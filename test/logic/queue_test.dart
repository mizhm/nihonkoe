import 'package:flutter_test/flutter_test.dart';
import 'package:nihonkoe/api/models.dart';
import 'package:nihonkoe/logic/queue.dart';
import 'package:nihonkoe/logic/sleep.dart';

PostDetail post(List<String> streams, {int id = 5}) => PostDetail(
      id: id,
      title: 'Work',
      cv: 'CV',
      cover: 'cover.jpg',
      streams: streams,
      tracks: const [Track(title: 'one', startSeconds: 0)],
    );

List<QueueItem> items(List<int> ids) => [for (final id in ids) queueItemsFor(post(['a.m3u8'], id: id)).single];
List<String> keys(List<QueueItem> list) => [for (final i in list) i.key];

void main() {
  test('queueItemsFor: one item per stream, chapters only on the first', () {
    final list = queueItemsFor(post(['a.m3u8', 'b.m3u8']));
    expect(keys(list), ['5:0', '5:1']);
    expect([for (final i in list) i.title], ['Work · 1', 'Work · 2']);
    expect(list[0].chapters.length, 1);
    expect(list[1].chapters, isEmpty);
    expect(list[0].post.id, 5);
    expect(list[0].post.cv, 'CV');
    expect(list[0].url, 'a.m3u8');
  });

  test('queueItemsFor: single stream keeps the plain title, no stream gives nothing', () {
    expect(queueItemsFor(post(['a.m3u8'])).single.title, 'Work');
    expect(queueItemsFor(post([])), isEmpty);
  });

  test('appendUnique skips items already queued', () {
    final [a, b] = queueItemsFor(post(['a.m3u8', 'b.m3u8']));
    expect(keys(appendUnique([a], [a, b])), ['5:0', '5:1']);
  });

  test('insertNext puts items right after the current one, moving duplicates but never the current item', () {
    final queue = items([1, 2, 3]);
    expect(keys(insertNext(queue, 0, items([9]))), ['1:0', '9:0', '2:0', '3:0']);
    expect(keys(insertNext(queue, 0, items([3]))), ['1:0', '3:0', '2:0']);
    expect(keys(insertNext(queue, 1, items([2, 9]))), ['1:0', '2:0', '9:0', '3:0']);
  });

  test('nextIndex', () {
    expect(nextIndex(3, 0, RepeatMode.off, true), 1);
    expect(nextIndex(3, 2, RepeatMode.off, true), isNull);
    expect(nextIndex(3, 2, RepeatMode.all, true), 0);
    expect(nextIndex(3, 1, RepeatMode.one, true), 1);
    expect(nextIndex(3, 1, RepeatMode.one, false), 2);
    expect(nextIndex(0, -1, RepeatMode.all, true), isNull);
  });

  test('previousIndex', () {
    expect(previousIndex(3, 2, RepeatMode.off), 1);
    expect(previousIndex(3, 0, RepeatMode.off), isNull);
    expect(previousIndex(3, 0, RepeatMode.all), 2);
  });

  test('nextRepeat cycles off → all → one → off', () {
    expect(nextRepeat(RepeatMode.off), RepeatMode.all);
    expect(nextRepeat(RepeatMode.all), RepeatMode.one);
    expect(nextRepeat(RepeatMode.one), RepeatMode.off);
  });

  test('shuffleKeepingCurrent puts the current item first and keeps every item', () {
    final shuffled = shuffleKeepingCurrent(['a', 'b', 'c', 'd'], 2, random: () => 0);
    expect(shuffled.first, 'c');
    expect([...shuffled]..sort(), ['a', 'b', 'c', 'd']);
    expect(shuffleKeepingCurrent(['a', 'b'], -1, random: () => 0).length, 2);
  });

  test('finishAction', () {
    final queue = items([1, 2, 3]);
    expect(finishAction(queue, 2, RepeatMode.off, const SleepOff()), isA<FinishStop>());
    expect(finishAction(queue, 1, RepeatMode.one, const SleepOff()), isA<FinishRestart>());
    expect((finishAction(queue, 0, RepeatMode.off, const SleepOff()) as FinishLoad).index, 1);
    expect((finishAction(queue, 2, RepeatMode.all, const SleepOff()) as FinishLoad).index, 0);
  });

  test('finishAction with an end-of-work sleep timer finishes the remaining streams of the same work', () {
    final queue = [...queueItemsFor(post(['a.m3u8', 'b.m3u8'])), ...items([9])];
    expect((finishAction(queue, 0, RepeatMode.off, const SleepItemEnd()) as FinishLoad).index, 1);
    expect(finishAction(queue, 1, RepeatMode.all, const SleepItemEnd()), isA<FinishStop>());
  });

  test('removeFromQueue removes from both orders and keeps the current item selected', () {
    final [a, b, c] = items([1, 2, 3]);
    final QueueState state = (queue: [c, a, b], ordered: [a, b, c], index: 1);
    final removed = removeFromQueue(state, c.key);
    expect(keys(removed.queue), ['1:0', '2:0']);
    expect(keys(removed.ordered), ['1:0', '2:0']);
    expect(removed.index, 0);
    expect(identical(removeFromQueue(state, a.key), state), isTrue, reason: 'the playing item cannot be removed');
  });

  test('moveInQueue keeps the current item selected', () {
    final [a, b, c] = items([1, 2, 3]);
    final QueueState state = (queue: [a, b, c], ordered: [a, b, c], index: 1);
    final moved = moveInQueue(state, 2, 0);
    expect(keys(moved.queue), ['3:0', '1:0', '2:0']);
    expect(moved.index, 2);
    expect(keys(moveInQueue(state, 1, 2).queue), ['1:0', '3:0', '2:0']);
    expect(moveInQueue(state, 1, 2).index, 2);
  });
}
