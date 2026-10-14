import 'dart:async';

import 'package:nihonkoe/api/models.dart';
import 'package:nihonkoe/data/db.dart';
import 'package:nihonkoe/logic/library.dart';
import 'package:nihonkoe/logic/position.dart';
import 'package:nihonkoe/logic/queue.dart';
import 'package:nihonkoe/player/engine.dart';
import 'package:nihonkoe/player/handler.dart';

class FakeEngine implements AudioEngine {
  final loads = <({String url, Map<String, String> headers})>[];
  Duration? nextDuration = const Duration(hours: 1);
  Object? nextLoadError;
  Completer<void>? loadGate;
  Completer<void>? speedGate;

  /// Positions from which audio became audible (just_audio keeps playing across a source change).
  final audibleFrom = <Duration>[];
  double speed = 1;
  EngineState state = EngineState.idle;
  Duration? duration;

  final _position = StreamController<Duration>.broadcast();
  final _status = StreamController<EngineStatus>.broadcast();
  final _errors = StreamController<Object>.broadcast();

  @override
  Duration position = Duration.zero;
  @override
  bool playing = false;

  @override
  Stream<Duration> get positionStream => _position.stream;
  @override
  Stream<EngineStatus> get statusStream => _status.stream;
  @override
  Stream<Object> get errorStream => _errors.stream;

  void _emit() => _status.add(EngineStatus(playing: playing, state: state, duration: duration, buffered: Duration.zero));

  @override
  Future<Duration?> load(String url, Map<String, String> headers) async {
    loads.add((url: url, headers: headers));
    // Like just_audio: `playing` survives setAudioSource, so a playing player starts the new source at once.
    state = EngineState.loading;
    _emit();
    final gate = loadGate;
    if (gate != null) await gate.future;
    if (nextLoadError case final error?) {
      nextLoadError = null;
      state = EngineState.idle;
      _emit();
      throw error;
    }
    position = Duration.zero;
    duration = nextDuration;
    state = EngineState.ready;
    if (playing) audibleFrom.add(position);
    _emit();
    return duration;
  }

  @override
  void play() {
    if (!playing && state != EngineState.loading) audibleFrom.add(position);
    playing = true;
    _emit();
  }

  @override
  Future<void> pause() async {
    playing = false;
    _emit();
  }

  @override
  Future<void> seek(Duration to) async {
    position = to;
    if (state == EngineState.completed) state = EngineState.ready;
  }

  @override
  Future<void> setSpeed(double value) async {
    speed = value;
    final gate = speedGate;
    if (gate != null) await gate.future;
  }

  @override
  Future<void> stop() async {
    playing = false;
    state = EngineState.idle;
    _emit();
  }

  void emitPosition(double seconds) {
    position = Duration(milliseconds: (seconds * 1000).round());
    _position.add(position);
  }

  /// Like just_audio: the position holds at the end and `playing` stays true.
  void complete() {
    position = duration ?? position;
    state = EngineState.completed;
    _emit();
  }

  /// Like just_audio on a mid-stream error: back to idle, `playing` still true, then the error.
  void fail(Object error) {
    state = EngineState.idle;
    _emit();
    _errors.add(error);
  }
}

class MemoryPositions implements PositionsRepo {
  final values = <String, double>{};
  @override
  Future<double?> get(String key) async => values[key];
  @override
  Future<void> save(String key, double? seconds) async => seconds == null ? values.remove(key) : values[key] = seconds;
  @override
  Future<ResumePoint?> inProgress(int postId) async => inProgressPosition(values, postId);
}

class MemoryHistory implements HistoryRepo {
  final plays = <PostRef>[];
  final _rows = <int, HistoryEntry>{};
  var _clock = 0;

  @override
  Future<void> recordPlay(PostRef post) async {
    plays.add(post);
    // Real time (the Library groups by day), nudged so two plays never share a stamp.
    _rows[post.id] = HistoryEntry(post: post, playedAt: DateTime.now().millisecondsSinceEpoch + ++_clock);
  }

  @override
  Future<List<HistoryEntry>> list() async => [..._rows.values]..sort((a, b) => b.playedAt.compareTo(a.playedAt));
  @override
  Future<void> remove(int postId) async => _rows.remove(postId);
  @override
  Future<void> clear() async => _rows.clear();
}

class MemoryFavorites implements FavoritesRepo {
  final _items = <PostRef>[];
  @override
  Future<List<PostRef>> list() async => List.of(_items);
  @override
  Future<bool> toggle(PostRef post) async {
    final had = _items.any((p) => p.id == post.id);
    _items.removeWhere((p) => p.id == post.id);
    if (!had) _items.insert(0, post);
    return !had;
  }
}

class MemoryRatings implements RatingsRepo {
  final _items = <int, RatedPost>{};
  @override
  Future<List<RatedPost>> list() async => [..._items.values]..sort((a, b) => b.rating.compareTo(a.rating));
  @override
  Future<void> set(PostRef post, int rating) async =>
      rating <= 0 ? _items.remove(post.id) : _items[post.id] = RatedPost(post: post, rating: rating);
}

NihonkoeAudioHandler makeHandler({FakeEngine? engine, MemoryPositions? positions, MemoryHistory? history, int Function()? now}) =>
    NihonkoeAudioHandler(
      engine: engine ?? FakeEngine(),
      positions: positions ?? MemoryPositions(),
      history: history ?? MemoryHistory(),
      now: now,
      random: () => 0,
      tick: false,
    );

QueueItem item(int id, {int stream = 0, List<Track> chapters = const []}) => QueueItem(
      key: '$id:$stream',
      post: PostRef(id: id, title: 'Work $id', cv: 'CV $id', cover: 'https://pic.weeabo0.xyz/$id.jpg'),
      title: 'Work $id',
      url: 'https://v.weeab0o.xyz/$id-$stream.m3u8',
      chapters: chapters,
    );
