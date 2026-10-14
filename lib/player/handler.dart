import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:rxdart/rxdart.dart';

import '../api/models.dart';
import '../data/db.dart';
import '../logic/position.dart';
import '../logic/queue.dart';
import '../logic/sleep.dart';
import 'engine.dart';

const _keep = Object();

class PlayerSnapshot {
  const PlayerSnapshot({
    this.queue = const [],
    this.ordered = const [],
    this.index = -1,
    this.repeat = RepeatMode.off,
    this.shuffle = false,
    this.rate = 1.0,
    this.sleep = const SleepOff(),
    this.error,
  });
  final List<QueueItem> queue; // play order (shuffled when [shuffle])
  final List<QueueItem> ordered; // the order the user added items
  final int index;
  final RepeatMode repeat;
  final bool shuffle;
  final double rate;
  final SleepTimer sleep;
  final String? error;

  QueueItem? get current => index >= 0 && index < queue.length ? queue[index] : null;

  PlayerSnapshot copyWith({
    List<QueueItem>? queue,
    List<QueueItem>? ordered,
    int? index,
    RepeatMode? repeat,
    bool? shuffle,
    double? rate,
    SleepTimer? sleep,
    Object? error = _keep,
  }) =>
      PlayerSnapshot(
        queue: queue ?? this.queue,
        ordered: ordered ?? this.ordered,
        index: index ?? this.index,
        repeat: repeat ?? this.repeat,
        shuffle: shuffle ?? this.shuffle,
        rate: rate ?? this.rate,
        sleep: sleep ?? this.sleep,
        error: identical(error, _keep) ? this.error : error as String?,
      );
}

class PlaybackInfo {
  const PlaybackInfo({this.playing = false, this.buffering = false, this.duration});
  final bool playing;
  final bool buffering;
  final Duration? duration;
}

double _seconds(Duration d) => d.inMilliseconds / 1000;
Duration _duration(double seconds) => Duration(milliseconds: (seconds * 1000).round());

class NihonkoeAudioHandler extends BaseAudioHandler {
  NihonkoeAudioHandler({
    required this._engine,
    required this._positions,
    required this._history,
    int Function()? now,
    this._random,
    bool tick = true,
  }) : _now = now ?? (() => DateTime.now().millisecondsSinceEpoch) {
    _subscriptions.addAll([
      _engine.positionStream.listen((p) => _tick(_seconds(p))),
      _engine.statusStream.listen(_onStatus),
      _engine.errorStream.listen(_onError, onError: _onError),
    ]);
    // Position events thin out while paused; a slow ticker keeps the sleep timer honest.
    if (tick) _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick(_seconds(_engine.position)));
  }

  final AudioEngine _engine;
  final PositionsRepo _positions;
  final HistoryRepo _history;
  final int Function() _now;
  final double Function()? _random;
  final _subscriptions = <StreamSubscription<Object?>>[];
  Timer? _ticker;

  final _state = BehaviorSubject.seeded(const PlayerSnapshot());
  final _playback = BehaviorSubject.seeded(const PlaybackInfo());

  ValueStream<PlayerSnapshot> get snapshots => _state.stream;
  PlayerSnapshot get snapshot => _state.value;
  ValueStream<PlaybackInfo> get playback => _playback.stream;
  Stream<Duration> get positionStream => _engine.positionStream;
  Duration get position => _engine.position;

  // Seconds to seek to once the current load finishes; also what a stop during loading keeps.
  double? _pendingSeek;
  double _lastSaved = 0;
  bool _ended = false;
  int _loadToken = 0;

  void _emit(PlayerSnapshot next) => _state.add(next);

  /// The handler's clock (epoch ms), so sleep deadlines and the labels the UI shows agree.
  int now() => _now();

  Future<void> _load(int index, {Duration? startAt}) async {
    final s = snapshot;
    if (index < 0 || index >= s.queue.length) return;
    final item = s.queue[index];
    final token = ++_loadToken;
    _emit(s.copyWith(index: index, error: null, sleep: s.sleep is SleepAtPosition ? const SleepOff() : null));
    _ended = false;
    final saved = startAt != null ? _seconds(startAt) : await _positions.get(item.key);
    if (token != _loadToken) return;
    _pendingSeek = saved;
    _lastSaved = saved ?? 0;
    mediaItem.add(_mediaItemFor(item, null));
    unawaited(_history.recordPlay(item.post).catchError((Object _) {}));
    try {
      final duration = await _engine.load(item.url, mediaHeaders);
      if (token != _loadToken) return;
      if (saved != null) {
        await _engine.seek(_duration(startAt != null ? saved : resumeTarget(saved, _seconds(duration ?? Duration.zero))));
      }
      if (token != _loadToken) return;
      _pendingSeek = null;
      await _engine.setSpeed(snapshot.rate);
      mediaItem.add(_mediaItemFor(item, duration));
      _engine.play();
    } catch (error) {
      if (token == _loadToken) _onError(error);
    }
  }

  MediaItem _mediaItemFor(QueueItem item, Duration? duration) => MediaItem(
        id: item.key,
        title: item.title,
        artist: item.post.cv,
        album: item.post.circle,
        artUri: item.post.cover == null ? null : Uri.parse(item.post.cover!),
        artHeaders: mediaHeaders,
        duration: duration,
      );

  /// Saves where the current item is, so switching works or stopping never loses more than nothing.
  Future<void> _saveCurrent() async {
    final item = snapshot.current;
    if (item == null) return;
    final at = stopPosition(_pendingSeek, _seconds(_engine.position), _ended);
    if (at != null) await _positions.save(item.key, at);
  }

  Future<void> playItems(List<QueueItem> items, {int start = 0, Duration? startAt}) async {
    if (start < 0 || start >= items.length) return;
    final target = items[start];
    if (snapshot.current?.key == target.key) {
      if (startAt != null) {
        _ended = false;
        await _engine.seek(startAt);
      }
      await play();
      return;
    }
    await _saveCurrent();
    final s = snapshot;
    _emit(s.copyWith(ordered: items, queue: s.shuffle ? shuffleKeepingCurrent(items, start, random: _random) : items));
    await _load(s.shuffle ? 0 : start, startAt: startAt);
  }

  @override
  Future<void> play() async {
    if (snapshot.current == null) return;
    if (_ended) {
      _ended = false;
      await _engine.seek(Duration.zero);
    }
    _engine.play();
  }

  @override
  Future<void> pause() async {
    await _engine.pause();
    await _saveCurrent();
  }

  Future<void> toggle() => _engine.playing ? pause() : play();

  @override
  Future<void> seek(Duration position) async {
    _ended = false;
    await _engine.seek(position < Duration.zero ? Duration.zero : position);
  }

  @override
  Future<void> stop() async {
    // Clear first so the UI drops the player in the same frame as the gesture that stopped it.
    final item = snapshot.current;
    final at = item == null ? null : stopPosition(_pendingSeek, _seconds(_engine.position), _ended);
    _loadToken++;
    _pendingSeek = null;
    _emit(snapshot.copyWith(queue: const [], ordered: const [], index: -1, error: null, sleep: const SleepOff()));
    mediaItem.add(null);
    if (item != null && at != null) await _positions.save(item.key, at);
    await _engine.stop();
    await super.stop();
  }

  void _tick(double position) {
    final item = snapshot.current;
    if (item == null || _pendingSeek != null) return;
    final playing = _engine.playing;
    if (shouldSavePosition(playing, position, _lastSaved)) {
      _lastSaved = position;
      unawaited(_positions.save(item.key, position).catchError((Object _) {}));
    }
  }

  void _onStatus(EngineStatus status) {
    _playback.add(PlaybackInfo(
      playing: status.playing,
      buffering: status.state == EngineState.loading || status.state == EngineState.buffering,
      duration: status.duration,
    ));
    playbackState.add(PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        status.playing ? MediaControl.pause : MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {MediaAction.seek, MediaAction.seekForward, MediaAction.seekBackward},
      androidCompactActionIndices: const [0, 1, 2],
      processingState: switch (status.state) {
        EngineState.idle => AudioProcessingState.idle,
        EngineState.loading => AudioProcessingState.loading,
        EngineState.buffering => AudioProcessingState.buffering,
        EngineState.ready => AudioProcessingState.ready,
        EngineState.completed => AudioProcessingState.completed,
      },
      playing: status.playing,
      updatePosition: _engine.position,
      bufferedPosition: status.buffered,
      speed: snapshot.rate,
      queueIndex: snapshot.index < 0 ? null : snapshot.index,
    ));
  }

  void _onError(Object error) => _emit(snapshot.copyWith(error: '$error'));

  Future<void> dispose() async {
    _ticker?.cancel();
    for (final s in _subscriptions) {
      await s.cancel();
    }
    await _state.close();
    await _playback.close();
  }
}
