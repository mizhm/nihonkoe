import 'dart:math';

import '../api/models.dart';
import 'sleep.dart';

class QueueItem {
  const QueueItem({required this.key, required this.post, required this.title, required this.url, this.chapters = const []});
  final String key; // "$postId:$streamIndex"
  final PostRef post;
  final String title;
  final String url;
  final List<Track> chapters;

  @override
  String toString() => 'QueueItem($key)';
}

enum RepeatMode { off, all, one }

RepeatMode nextRepeat(RepeatMode mode) => RepeatMode.values[(mode.index + 1) % RepeatMode.values.length];

List<QueueItem> queueItemsFor(PostDetail post) {
  final ref = PostRef.fromDetail(post);
  final many = post.streams.length > 1;
  return [
    for (final (i, url) in post.streams.indexed)
      QueueItem(
        key: '${post.id}:$i',
        post: ref,
        title: many ? '${post.title} · ${i + 1}' : post.title,
        url: url,
        // The site renders one tracklist, for the first player only.
        chapters: i == 0 ? post.tracks : const [],
      ),
  ];
}

List<QueueItem> appendUnique(List<QueueItem> queue, List<QueueItem> items) {
  final keys = {for (final i in queue) i.key};
  return [...queue, for (final i in items) if (keys.add(i.key)) i];
}

List<QueueItem> insertNext(List<QueueItem> queue, int current, List<QueueItem> items) {
  final currentKey = current >= 0 && current < queue.length ? queue[current].key : null;
  final incoming = [for (final i in items) if (i.key != currentKey) i];
  final moving = {for (final i in incoming) i.key};
  final rest = [for (final i in queue) if (!moving.contains(i.key)) i];
  final at = currentKey == null ? 0 : rest.indexWhere((i) => i.key == currentKey) + 1;
  return [...rest.sublist(0, at), ...incoming, ...rest.sublist(at)];
}

int? nextIndex(int length, int current, RepeatMode repeat, bool ended) {
  if (length == 0) return null;
  if (ended && repeat == RepeatMode.one) return current;
  if (current + 1 < length) return current + 1;
  return repeat == RepeatMode.off ? null : 0;
}

int? previousIndex(int length, int current, RepeatMode repeat) {
  if (current > 0) return current - 1;
  return repeat == RepeatMode.off || length == 0 ? null : length - 1;
}

sealed class FinishAction {
  const FinishAction();
}

class FinishStop extends FinishAction {
  const FinishStop();
}

class FinishRestart extends FinishAction {
  const FinishRestart();
}

class FinishLoad extends FinishAction {
  const FinishLoad(this.index);
  final int index;
}

FinishAction finishAction(List<QueueItem> queue, int index, RepeatMode repeat, SleepTimer sleep) {
  if (sleep is SleepItemEnd) {
    // "End of work" lets the remaining streams of a multi-part work play out.
    final next = index + 1 < queue.length ? queue[index + 1] : null;
    return next != null && next.post.id == queue[index].post.id ? FinishLoad(index + 1) : const FinishStop();
  }
  final next = nextIndex(queue.length, index, repeat, true);
  if (next == null) return const FinishStop();
  return next == index ? const FinishRestart() : FinishLoad(next);
}

typedef QueueState = ({List<QueueItem> queue, List<QueueItem> ordered, int index});

QueueState removeFromQueue(QueueState state, String key) {
  if (state.index < 0 || state.index >= state.queue.length) return state;
  final current = state.queue[state.index];
  if (current.key == key) return state;
  final queue = [for (final i in state.queue) if (i.key != key) i];
  return (
    queue: queue,
    ordered: [for (final i in state.ordered) if (i.key != key) i],
    index: queue.indexOf(current),
  );
}

QueueState moveInQueue(QueueState state, int from, int to) {
  if (from == to || from < 0 || from >= state.queue.length || to < 0 || to >= state.queue.length) return state;
  final current = state.index >= 0 && state.index < state.queue.length ? state.queue[state.index] : null;
  final queue = [...state.queue];
  queue.insert(to, queue.removeAt(from));
  return (queue: queue, ordered: state.ordered, index: current == null ? state.index : queue.indexOf(current));
}

List<T> shuffleKeepingCurrent<T>(List<T> items, int current, {double Function()? random}) {
  final next = random ?? Random().nextDouble;
  final rest = [for (final (i, item) in items.indexed) if (i != current) item];
  for (var i = rest.length - 1; i > 0; i--) {
    final j = (next() * (i + 1)).floor();
    final tmp = rest[i];
    rest[i] = rest[j];
    rest[j] = tmp;
  }
  return current >= 0 && current < items.length ? [items[current], ...rest] : rest;
}
