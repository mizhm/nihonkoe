import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nihonkoe/logic/sleep.dart';

import '../player_fakes.dart';

class ThrowingPauseEngine extends FakeEngine {
  @override
  Future<void> pause() async => throw StateError('platform gone');
}

void main() {
  test('next chapter past the last one saves the current position before moving on', () async {
    final positions = MemoryPositions();
    final engine = FakeEngine();
    final h = makeHandler(engine: engine, positions: positions);
    await h.playItems([item(1), item(2)]);
    engine.position = const Duration(seconds: 50);
    await h.nextChapter();
    expect(positions.values['1:0'], 50);
    expect(h.snapshot.current!.key, '2:0');
  });

  test('a sleep timer pause that throws does not escape as an unhandled error', () async {
    final errors = <Object>[];
    await runZonedGuarded(() async {
      var now = 0;
      final engine = ThrowingPauseEngine();
      final h = makeHandler(engine: engine, now: () => now);
      await h.playItems([item(1)]);
      h.setSleep(const SleepAt(1000));
      now = 2000;
      engine.emitPosition(1);
      await pumpEventQueue();
    }, (e, _) => errors.add(e));
    expect(errors, isEmpty);
  });

  test('pressing Play on the item that failed reloads it instead of resuming a dead source', () async {
    final engine = FakeEngine()..nextLoadError = Exception('403');
    final h = makeHandler(engine: engine);
    await h.playItems([item(1)]);
    expect(h.snapshot.error, isNotNull);
    await h.playItems([item(1)]);
    expect(engine.loads.length, 2);
    expect(h.snapshot.error, isNull);
    expect(engine.playing, isTrue);
  });

  test('a chapter tap while the item is still loading is not lost', () async {
    final engine = FakeEngine()..loadGate = Completer<void>();
    final h = makeHandler(engine: engine);
    unawaited(h.playItems([item(1)]));
    await pumpEventQueue();
    final second = h.playItems([item(1)], startAt: const Duration(seconds: 607));
    engine.loadGate!.complete();
    engine.loadGate = null;
    await second;
    await pumpEventQueue();
    expect(engine.position, const Duration(seconds: 607));
    expect(engine.playing, isTrue);
  });

  test('Play or a seek after an error reloads the source and clears the error', () async {
    final engine = FakeEngine();
    final h = makeHandler(engine: engine);
    await h.playItems([item(1)]);
    engine.emitPosition(40);
    await pumpEventQueue();
    engine.fail(Exception('Source error'));
    await pumpEventQueue();
    await h.play();
    expect(h.snapshot.error, isNull);
    expect(engine.loads.length, 2);
    expect(engine.position, const Duration(seconds: 40));
    engine.fail(Exception('Source error'));
    await pumpEventQueue();
    await h.seek(const Duration(seconds: 90));
    expect(h.snapshot.error, isNull);
    expect(engine.loads.length, 3);
    expect(engine.position, const Duration(seconds: 90));
  });

  test('a manual reorder survives turning shuffle on and off', () async {
    final h = makeHandler();
    await h.playItems([item(1), item(2), item(3)]);
    h.moveItem(2, 1);
    h.toggleShuffle();
    h.toggleShuffle();
    expect([for (final i in h.snapshot.queue) i.key], ['1:0', '3:0', '2:0']);
  });

  test('savedPositions ticks after a pause has written the position', () async {
    final positions = MemoryPositions();
    final engine = FakeEngine();
    final h = makeHandler(engine: engine, positions: positions);
    await h.playItems([item(1)]);
    final before = h.savedPositions.value;
    engine.position = const Duration(seconds: 30);
    await h.pause();
    await pumpEventQueue();
    expect(h.savedPositions.value, greaterThan(before));
    expect(positions.values['1:0'], 30);
  });
}
