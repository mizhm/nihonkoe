import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nihonkoe/api/models.dart';

import '../player_fakes.dart';

void main() {
  test('playItems loads with the Referer header, plays, records history and publishes the media item', () async {
    final engine = FakeEngine();
    final history = MemoryHistory();
    final h = makeHandler(engine: engine, history: history);
    await h.playItems([item(1), item(2)]);
    expect(engine.loads.single.url, 'https://v.weeab0o.xyz/1-0.m3u8');
    expect(engine.loads.single.headers, mediaHeaders);
    expect(engine.playing, isTrue);
    expect(h.snapshot.current!.key, '1:0');
    expect(history.plays.single.id, 1);
    final media = h.mediaItem.value!;
    expect(media.title, 'Work 1');
    expect(media.artist, 'CV 1');
    expect(media.artUri.toString(), 'https://pic.weeabo0.xyz/1.jpg');
    expect(media.artHeaders, mediaHeaders);
    expect(media.duration, const Duration(hours: 1));
  });

  test('resumes a saved position, but restarts a work left in its last seconds', () async {
    final positions = MemoryPositions()..values['1:0'] = 120;
    final engine = FakeEngine();
    final h = makeHandler(engine: engine, positions: positions);
    await h.playItems([item(1)]);
    expect(engine.position, const Duration(seconds: 120));
    positions.values['2:0'] = 3595;
    await h.playItems([item(2)]);
    expect(engine.position, Duration.zero);
  });

  test('an explicit start position wins over the saved one', () async {
    final positions = MemoryPositions()..values['1:0'] = 120;
    final engine = FakeEngine();
    final h = makeHandler(engine: engine, positions: positions);
    await h.playItems([item(1)], startAt: const Duration(seconds: 607));
    expect(engine.position, const Duration(seconds: 607));
  });

  test('switching to another work saves the exact position of the one playing', () async {
    final positions = MemoryPositions();
    final engine = FakeEngine();
    final h = makeHandler(engine: engine, positions: positions);
    await h.playItems([item(1)]);
    engine.position = const Duration(seconds: 123);
    await h.playItems([item(2)]);
    expect(positions.values['1:0'], 123);
  });

  test('saves the position every 5 s while playing', () async {
    final positions = MemoryPositions();
    final engine = FakeEngine();
    final h = makeHandler(engine: engine, positions: positions);
    await h.playItems([item(1)]);
    engine.emitPosition(4);
    await pumpEventQueue();
    expect(positions.values['1:0'], isNull);
    engine.emitPosition(5);
    await pumpEventQueue();
    expect(positions.values['1:0'], 5);
  });

  test('pressing play on the playing item resumes instead of reloading', () async {
    final engine = FakeEngine();
    final h = makeHandler(engine: engine);
    await h.playItems([item(1)]);
    await h.pause();
    await h.playItems([item(1)]);
    expect(engine.loads.length, 1);
    expect(engine.playing, isTrue);
  });

  test('toggle pauses and resumes; pause saves the position', () async {
    final positions = MemoryPositions();
    final engine = FakeEngine();
    final h = makeHandler(engine: engine, positions: positions);
    await h.playItems([item(1)]);
    engine.position = const Duration(seconds: 42);
    await h.toggle();
    expect(engine.playing, isFalse);
    expect(positions.values['1:0'], 42);
    await h.toggle();
    expect(engine.playing, isTrue);
  });

  test('a load superseded by a newer one never starts playing or overwrites the newer item', () async {
    final gate = Completer<void>();
    final engine = FakeEngine()..loadGate = gate;
    final h = makeHandler(engine: engine);
    final first = h.playItems([item(1)]); // stuck in engine.load
    await pumpEventQueue();
    engine.loadGate = null;
    await h.playItems([item(2)]);
    expect(engine.playing, isTrue);
    await engine.pause(); // so a late play() from the first load would be visible
    gate.complete(); // the first load finishes late
    await first;
    await pumpEventQueue();
    expect(engine.loads.map((l) => l.url), [contains('/1-0'), contains('/2-0')]);
    expect(engine.playing, isFalse, reason: 'the superseded load must not call play()');
    expect(h.snapshot.current!.key, '2:0');
    expect(h.mediaItem.value!.id, '2:0');
  });

  test('stop keeps the listening position (even while the resume seek is pending) and clears the queue', () async {
    final positions = MemoryPositions()..values['1:0'] = 300;
    final engine = FakeEngine()..loadGate = Completer<void>();
    final h = makeHandler(engine: engine, positions: positions);
    unawaited(h.playItems([item(1)]));
    await pumpEventQueue();
    await h.stop();
    expect(positions.values['1:0'], 300);
    expect(h.snapshot.queue, isEmpty);
    expect(h.snapshot.current, isNull);
    expect(h.mediaItem.value, isNull);
  });
}
