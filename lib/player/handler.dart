import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:rxdart/rxdart.dart';

import '../api/models.dart';
import '../data/db.dart';
import '../logic/chapters.dart';
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
  }) => PlayerSnapshot(
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
  double _lastPosition = 0;
  bool _wasPlaying = false;
  int _loadToken = 0;
  // False from the start of a load until the new item's saved position is read: until then
  // just_audio still reports the previous source's position, which must never be saved for this item.
  bool _positionKnown = true;
  EngineStatus _lastStatus = const EngineStatus(playing: false, state: EngineState.idle);
  EngineState _lastState = EngineState.idle;

  void _emit(PlayerSnapshot next) => _state.add(next);

  /// The handler's clock (epoch ms), so sleep deadlines and the labels the UI shows agree.
  int now() => _now();

  Future<void> _load(int index, {Duration? startAt}) async {
    final s = snapshot;
    if (index < 0 || index >= s.queue.length) return;
    final item = s.queue[index];
    final token = ++_loadToken;
    _positionKnown = false;
    _emit(s.copyWith(index: index, error: null, sleep: s.sleep is SleepAtPosition ? const SleepOff() : null));
    _ended = false;
    final saved = startAt != null ? _seconds(startAt) : await _positions.get(item.key);
    if (token != _loadToken) return;
    _pendingSeek = saved ?? 0;
    _positionKnown = true;
    _lastSaved = saved ?? 0;
    _lastPosition = saved ?? 0;
    unawaited(_history.recordPlay(item.post).catchError((Object _) {}));
    try {
      mediaItem.add(_mediaItemFor(item, null));
      // just_audio keeps playing across a source change; pause so the new work isn't heard from 0 before its seek.
      if (_engine.playing) await _engine.pause();
      if (token != _loadToken) return;
      final duration = await _engine.load(item.url, mediaHeaders);
      if (token != _loadToken) return;
      if (saved != null) {
        await _engine.seek(
          _duration(startAt != null ? saved : resumeTarget(saved, _seconds(duration ?? Duration.zero))),
        );
      }
      if (token != _loadToken) return;
      _pendingSeek = null;
      await _engine.setSpeed(snapshot.rate);
      if (token != _loadToken) return;
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
    if (item == null || !_positionKnown) return;
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
    _emit(
      s.copyWith(
        ordered: items,
        queue: s.shuffle ? shuffleKeepingCurrent(items, start, random: _random) : items,
      ),
    );
    await _load(s.shuffle ? 0 : start, startAt: startAt);
  }

  @override
  Future<void> play() async {
    if (snapshot.current == null) return;
    final token = _loadToken;
    if (_ended) {
      _ended = false;
      await _engine.seek(Duration.zero);
      if (token != _loadToken || snapshot.current == null) return;
    }
    _engine.play();
  }

  @override
  Future<void> pause() async {
    await _engine.pause();
    _wasPlaying = false; // a sleep timer that expires during the pause must not count as "was playing"
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
    final at = item == null || !_positionKnown ? null : stopPosition(_pendingSeek, _seconds(_engine.position), _ended);
    _loadToken++;
    _pendingSeek = null;
    _positionKnown = true;
    _emit(snapshot.copyWith(queue: const [], ordered: const [], index: -1, error: null, sleep: const SleepOff()));
    mediaItem.add(null);
    if (item != null && at != null) await _positions.save(item.key, at);
    await _engine.stop();
    await super.stop();
  }

  void _tick(double position) {
    final item = snapshot.current;
    // Nothing to track while loading, after the end (the position sits at the duration) or after an error
    // (just_audio's position is stale then; Retry needs the last good one).
    if (item == null || !_positionKnown || _pendingSeek != null || _ended || snapshot.error != null) return;
    _lastPosition = position;
    final playing = _engine.playing;
    final action = sleepAction(snapshot.sleep, _now(), item.key, position, _wasPlaying || playing);
    if (action == SleepAction.pause) unawaited(pause());
    if (action != SleepAction.none) _emit(snapshot.copyWith(sleep: const SleepOff()));
    if (shouldSavePosition(playing, position, _lastSaved)) {
      _lastSaved = position;
      unawaited(_positions.save(item.key, position).catchError((Object _) {}));
    }
    _wasPlaying = action == SleepAction.pause ? false : playing;
  }

  @visibleForTesting
  void tickForTest() => _tick(_seconds(_engine.position));

  void _onStatus(EngineStatus status) {
    _playback.add(
      PlaybackInfo(
        playing: status.playing,
        buffering: status.state == EngineState.loading || status.state == EngineState.buffering,
        duration: status.duration,
      ),
    );
    _lastStatus = status;
    _broadcast();
    if (status.state == EngineState.completed && _lastState != EngineState.completed) {
      final item = snapshot.current;
      if (item != null) unawaited(_finish(item).catchError((Object e) => _onError(e)));
    }
    _lastState = status.state;
  }

  void _broadcast() {
    final status = _lastStatus;
    final error = snapshot.error;
    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          status.playing ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {MediaAction.seek, MediaAction.seekForward, MediaAction.seekBackward},
        androidCompactActionIndices: const [0, 1, 2],
        // An error keeps the notification (audio_service stops the service on idle) and shows the failure.
        processingState: error != null
            ? AudioProcessingState.error
            : switch (status.state) {
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
        errorMessage: error,
      ),
    );
  }

  Future<void> _finish(QueueItem item) async {
    final token = _loadToken;
    await _positions.save(item.key, null);
    if (token != _loadToken) return; // the user jumped or stopped meanwhile
    final s = snapshot;
    switch (finishAction(s.queue, s.index, s.repeat, s.sleep)) {
      case FinishStop():
        _ended = true;
        await _engine.pause();
        if (s.sleep is SleepItemEnd) _emit(snapshot.copyWith(sleep: const SleepOff()));
      case FinishRestart():
        await _engine.seek(Duration.zero);
        if (token == _loadToken) _engine.play();
      case FinishLoad(:final index):
        await _load(index, startAt: Duration.zero);
    }
  }

  Future<void> enqueue(List<QueueItem> items) async {
    final s = snapshot;
    if (s.current == null) return playItems(items);
    _emit(s.copyWith(queue: appendUnique(s.queue, items), ordered: appendUnique(s.ordered, items)));
  }

  Future<void> playNextItems(List<QueueItem> items) async {
    final s = snapshot;
    final current = s.current;
    if (current == null) return playItems(items);
    _emit(
      s.copyWith(
        queue: insertNext(s.queue, s.index, items),
        ordered: insertNext(s.ordered, s.ordered.indexWhere((i) => i.key == current.key), items),
      ),
    );
  }

  Future<void> nextChapter() async {
    final item = snapshot.current;
    if (item == null) return;
    final start = nextChapterStart(item.chapters, _seconds(_engine.position));
    if (start != null) return seek(_duration(start));
    final s = snapshot;
    final next = nextIndex(s.queue.length, s.index, s.repeat, false);
    if (next != null) await _load(next, startAt: Duration.zero);
  }

  Future<void> previousChapter() async {
    final s = snapshot;
    final item = s.current;
    if (item == null) return;
    final position = _seconds(_engine.position);
    final previous = previousIndex(s.queue.length, s.index, s.repeat);
    if (position <= restartThresholdSeconds && previous != null) {
      await _saveCurrent();
      return _load(previous, startAt: Duration.zero);
    }
    await seek(_duration(previousChapterStart(item.chapters, position)));
  }

  Future<void> seekBy(int seconds) => seek(_engine.position + Duration(seconds: seconds));

  Future<void> jumpTo(int index) async {
    if (index == snapshot.index) return;
    await _saveCurrent();
    await _load(index);
  }

  void removeKey(String key) {
    final s = snapshot;
    final next = removeFromQueue((queue: s.queue, ordered: s.ordered, index: s.index), key);
    _emit(s.copyWith(queue: next.queue, ordered: next.ordered, index: next.index));
  }

  void moveItem(int from, int to) {
    final s = snapshot;
    final next = moveInQueue((queue: s.queue, ordered: s.ordered, index: s.index), from, to);
    _emit(s.copyWith(queue: next.queue, index: next.index));
  }

  void cycleRepeat() => _emit(snapshot.copyWith(repeat: nextRepeat(snapshot.repeat)));

  void toggleShuffle() {
    final s = snapshot;
    final current = s.current;
    if (current == null) return _emit(s.copyWith(shuffle: !s.shuffle));
    final at = s.ordered.indexWhere((i) => i.key == current.key);
    if (s.shuffle) return _emit(s.copyWith(shuffle: false, queue: s.ordered, index: at));
    _emit(s.copyWith(shuffle: true, queue: shuffleKeepingCurrent(s.ordered, at, random: _random), index: 0));
  }

  @override
  Future<void> setSpeed(double speed) async {
    _emit(snapshot.copyWith(rate: speed));
    await _engine.setSpeed(speed);
  }

  // Headset and notification buttons: chapters first, like the in-app skip buttons.
  @override
  Future<void> skipToNext() => nextChapter();
  @override
  Future<void> skipToPrevious() => previousChapter();
  @override
  Future<void> skipToQueueItem(int index) => jumpTo(index);
  @override
  Future<void> fastForward() => seekBy(30);
  @override
  Future<void> rewind() => seekBy(-15);

  void setSleep(SleepTimer timer) => _emit(snapshot.copyWith(sleep: timer));

  void extendSleepBy(int minutes) => _emit(snapshot.copyWith(sleep: extendSleep(snapshot.sleep, minutes, _now())));

  /// Reloads the current item where the listener had got to (a failed source reports position 0).
  Future<void> retry() async {
    final s = snapshot;
    if (s.current == null) return;
    final at = _seconds(_engine.position) > 0 ? _seconds(_engine.position) : _lastPosition;
    await _load(s.index, startAt: _duration(at));
  }

  void _onError(Object error) {
    _emit(snapshot.copyWith(error: '$error'));
    // just_audio leaves `playing` true after an error; pause so the UI and notification show the truth.
    _wasPlaying = false;
    unawaited(_engine.pause().catchError((Object _) {}));
    _broadcast();
  }

  Future<void> dispose() async {
    _ticker?.cancel();
    for (final s in _subscriptions) {
      await s.cancel();
    }
    await _state.close();
    await _playback.close();
  }
}
