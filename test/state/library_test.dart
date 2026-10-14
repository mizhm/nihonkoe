import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihonkoe/api/models.dart';
import 'package:nihonkoe/state/library.dart';
import 'package:nihonkoe/state/player.dart';

import '../player_fakes.dart';

void main() {
  late MemoryHistory history;
  late ProviderContainer c;

  setUp(() {
    history = MemoryHistory();
    final handler = makeHandler(history: history);
    c = ProviderContainer.test(overrides: [
      audioHandlerProvider.overrideWithValue(handler),
      favoritesRepoProvider.overrideWithValue(MemoryFavorites()),
      historyRepoProvider.overrideWithValue(history),
      ratingsRepoProvider.overrideWithValue(MemoryRatings()),
    ]);
    c.listen(libraryProvider, (_, _) {});
  });

  test('favorites and ratings round-trip through the notifier', () async {
    final n = c.read(libraryProvider.notifier);
    await c.read(libraryProvider.future);
    await n.toggleFavorite(const PostRef(id: 1, title: 'a'));
    await n.setRating(const PostRef(id: 1, title: 'a'), 4);
    final data = c.read(libraryProvider).value!;
    expect(data.isFavorite(1), isTrue);
    expect(data.ratingOf(1), 4);
    expect(data.ratingOf(2), 0);
    await n.toggleFavorite(const PostRef(id: 1, title: 'a'));
    await n.setRating(const PostRef(id: 1, title: 'a'), 0);
    expect(c.read(libraryProvider).value!.isFavorite(1), isFalse);
    expect(c.read(libraryProvider).value!.ratings, isEmpty);
  });

  test('a play recorded by the player shows up in history without a manual refresh', () async {
    await c.read(libraryProvider.future);
    await c.read(audioHandlerProvider).playItems([item(7)]);
    await pumpEventQueue();
    expect([for (final e in (await c.read(libraryProvider.future)).history) e.post.id], [7]);
  });

  test('remove one and clear history', () async {
    final n = c.read(libraryProvider.notifier);
    await history.recordPlay(const PostRef(id: 1, title: 'a'));
    await history.recordPlay(const PostRef(id: 2, title: 'b'));
    c.invalidate(libraryProvider);
    await c.read(libraryProvider.future);
    await n.removeFromHistory(1);
    expect([for (final e in c.read(libraryProvider).value!.history) e.post.id], [2]);
    await n.clearHistory();
    expect(c.read(libraryProvider).value!.history, isEmpty);
  });
}
