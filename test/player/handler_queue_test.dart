import 'package:flutter_test/flutter_test.dart';
import 'package:nihonkoe/api/models.dart';
import 'package:nihonkoe/logic/queue.dart';

import '../player_fakes.dart';

const chapters = [Track(title: 'a', startSeconds: 0), Track(title: 'b', startSeconds: 100), Track(title: 'c', startSeconds: 250)];

List<String> keys(List<QueueItem> list) => [for (final i in list) i.key];

void main() {
  test('a finished item clears its position and the next one starts from 0', () async {
    final positions = MemoryPositions()..values['2:0'] = 77;
    final engine = FakeEngine();
    final h = makeHandler(engine: engine, positions: positions);
    await h.playItems([item(1), item(2)]);
    positions.values['1:0'] = 50;
    engine.complete();
    await pumpEventQueue();
    expect(positions.values.containsKey('1:0'), isFalse);
    expect(h.snapshot.current!.key, '2:0');
    expect(engine.position, Duration.zero);
  });

  test('the end of the queue stops; Play afterwards restarts from the beginning', () async {
    final engine = FakeEngine();
    final h = makeHandler(engine: engine);
    await h.playItems([item(1)]);
    engine.position = const Duration(minutes: 59);
    engine.complete();
    await pumpEventQueue();
    expect(engine.playing, isFalse);
    expect(h.snapshot.current!.key, '1:0');
    await h.play();
    expect(engine.position, Duration.zero);
    expect(engine.playing, isTrue);
  });

  test('repeat one restarts the item; repeat all wraps to the first', () async {
    final engine = FakeEngine();
    final h = makeHandler(engine: engine);
    await h.playItems([item(1), item(2)]);
    h.cycleRepeat(); // all
    h.cycleRepeat(); // one
    engine.position = const Duration(minutes: 59);
    engine.complete();
    await pumpEventQueue();
    expect(h.snapshot.current!.key, '1:0');
    expect(engine.position, Duration.zero);
    h.cycleRepeat(); // off
    h.cycleRepeat(); // all
    await h.jumpTo(1);
    engine.complete();
    await pumpEventQueue();
    expect(h.snapshot.current!.key, '1:0');
  });

  test('nextChapter seeks within the item, then moves to the next item after the last chapter', () async {
    final engine = FakeEngine();
    final h = makeHandler(engine: engine);
    await h.playItems([item(1, chapters: chapters), item(2)]);
    engine.position = const Duration(seconds: 150);
    await h.nextChapter();
    expect(engine.position, const Duration(seconds: 250));
    await h.nextChapter();
    expect(h.snapshot.current!.key, '2:0');
  });

  test('previousChapter restarts the chapter, or goes to the previous item near the start', () async {
    final engine = FakeEngine();
    final h = makeHandler(engine: engine);
    await h.playItems([item(1), item(2, chapters: chapters)], start: 1);
    engine.position = const Duration(seconds: 150);
    await h.previousChapter();
    expect(engine.position, const Duration(seconds: 100));
    engine.position = const Duration(seconds: 2);
    await h.previousChapter();
    expect(h.snapshot.current!.key, '1:0');
  });

  test('notification skip buttons are chapter skips; fast-forward/rewind are +30/-15 s', () async {
    final engine = FakeEngine();
    final h = makeHandler(engine: engine);
    await h.playItems([item(1, chapters: chapters)]);
    engine.position = const Duration(seconds: 10);
    await h.skipToNext();
    expect(engine.position, const Duration(seconds: 100));
    await h.fastForward();
    expect(engine.position, const Duration(seconds: 130));
    await h.rewind();
    expect(engine.position, const Duration(seconds: 115));
    engine.position = const Duration(seconds: 5);
    await h.rewind();
    expect(engine.position, Duration.zero);
  });

  test('enqueue on an empty player starts it; otherwise appends without duplicates', () async {
    final engine = FakeEngine();
    final h = makeHandler(engine: engine);
    await h.enqueue([item(1)]);
    expect(engine.playing, isTrue);
    await h.enqueue([item(1), item(2)]);
    expect(keys(h.snapshot.queue), ['1:0', '2:0']);
    expect(engine.loads.length, 1);
  });

  test('playNextItems inserts right after the current item in both orders', () async {
    final h = makeHandler();
    await h.playItems([item(1), item(2), item(3)]);
    await h.playNextItems([item(9)]);
    expect(keys(h.snapshot.queue), ['1:0', '9:0', '2:0', '3:0']);
    expect(keys(h.snapshot.ordered), ['1:0', '9:0', '2:0', '3:0']);
    expect(h.snapshot.current!.key, '1:0');
  });

  test('removeKey cannot remove the playing item; moveItem keeps it selected', () async {
    final h = makeHandler();
    await h.playItems([item(1), item(2), item(3)], start: 1);
    h.removeKey('2:0');
    expect(keys(h.snapshot.queue), ['1:0', '2:0', '3:0']);
    h.removeKey('1:0');
    expect(keys(h.snapshot.queue), ['2:0', '3:0']);
    expect(h.snapshot.current!.key, '2:0');
    h.moveItem(1, 0);
    expect(keys(h.snapshot.queue), ['3:0', '2:0']);
    expect(h.snapshot.current!.key, '2:0');
  });

  test('toggleShuffle keeps the current item playing and restores the original order', () async {
    final h = makeHandler();
    await h.playItems([item(1), item(2), item(3)], start: 1);
    h.toggleShuffle();
    expect(h.snapshot.shuffle, isTrue);
    expect(h.snapshot.current!.key, '2:0');
    expect(h.snapshot.index, 0);
    h.toggleShuffle();
    expect(keys(h.snapshot.queue), ['1:0', '2:0', '3:0']);
    expect(h.snapshot.current!.key, '2:0');
  });

  test('setSpeed applies now and to later items', () async {
    final engine = FakeEngine();
    final h = makeHandler(engine: engine);
    await h.playItems([item(1), item(2)]);
    await h.setSpeed(1.5);
    expect(engine.speed, 1.5);
    engine.speed = 1;
    await h.jumpTo(1);
    expect(engine.speed, 1.5);
    expect(h.snapshot.rate, 1.5);
  });
}
