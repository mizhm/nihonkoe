import 'package:flutter_test/flutter_test.dart';
import 'package:nihonkoe/logic/sleep.dart';

import '../player_fakes.dart';

void main() {
  test('a minute timer pauses playback when due and clears itself', () async {
    var now = 0;
    final engine = FakeEngine();
    final h = makeHandler(engine: engine, now: () => now);
    await h.playItems([item(1)]);
    h.setSleep(const SleepAt(60000));
    engine.emitPosition(1);
    await pumpEventQueue();
    expect(engine.playing, isTrue);
    now = 60000;
    engine.emitPosition(2);
    await pumpEventQueue();
    expect(engine.playing, isFalse);
    expect(h.snapshot.sleep, const SleepOff());
  });

  test('a timer that expires while paused is cleared and does not pause the next resume', () async {
    var now = 0;
    final engine = FakeEngine();
    final h = makeHandler(engine: engine, now: () => now);
    await h.playItems([item(1)]);
    h.setSleep(const SleepAt(60000));
    await h.pause();
    h.tickForTest();
    now = 120000;
    h.tickForTest();
    expect(h.snapshot.sleep, const SleepOff());
    await h.play();
    h.tickForTest();
    expect(engine.playing, isTrue);
  });

  test('end of chapter pauses at the chapter end and is dropped when another item loads', () async {
    final engine = FakeEngine();
    final h = makeHandler(engine: engine);
    await h.playItems([item(1), item(2)]);
    h.setSleep(const SleepAtPosition('1:0', 100));
    engine.emitPosition(100);
    await pumpEventQueue();
    expect(engine.playing, isFalse);
    h.setSleep(const SleepAtPosition('1:0', 200));
    await h.jumpTo(1);
    expect(h.snapshot.sleep, const SleepOff());
  });

  test('end of work plays the remaining streams of the work, then stops and clears', () async {
    final engine = FakeEngine();
    final h = makeHandler(engine: engine);
    await h.playItems([item(1, stream: 0), item(1, stream: 1), item(2)]);
    h.setSleep(const SleepItemEnd());
    engine.complete();
    await pumpEventQueue();
    expect(h.snapshot.current!.key, '1:1');
    engine.complete();
    await pumpEventQueue();
    expect(h.snapshot.current!.key, '1:1');
    expect(engine.playing, isFalse);
    expect(h.snapshot.sleep, const SleepOff());
  });

  test('extendSleepBy adds minutes to a minute timer', () async {
    final h = makeHandler(now: () => 0);
    h.setSleep(const SleepAt(60000));
    h.extendSleepBy(10);
    expect(h.snapshot.sleep, const SleepAt(60000 + 600000));
  });

  test('a load error is shown; retry reloads the same item at the position reached', () async {
    final engine = FakeEngine();
    final h = makeHandler(engine: engine);
    await h.playItems([item(1)]);
    engine.emitPosition(321);
    await pumpEventQueue();
    engine.fail(Exception('Source error'));
    await pumpEventQueue();
    expect(h.snapshot.error, contains('Source error'));
    engine.position = Duration.zero; // the failed source lost its position
    await h.retry();
    expect(h.snapshot.error, isNull);
    expect(engine.loads.length, 2);
    expect(engine.position, const Duration(seconds: 321));
    expect(engine.playing, isTrue);
  });

  test('a failed first load surfaces the error and Retry tries again', () async {
    final engine = FakeEngine()..nextLoadError = Exception('403');
    final h = makeHandler(engine: engine);
    await h.playItems([item(1)]);
    expect(h.snapshot.error, contains('403'));
    expect(engine.playing, isFalse);
    await h.retry();
    expect(h.snapshot.error, isNull);
    expect(engine.playing, isTrue);
  });
}
