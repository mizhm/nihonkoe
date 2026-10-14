import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/models.dart';
import '../data/db.dart';
import '../logic/library.dart';
import 'core.dart';
import 'player.dart';

final favoritesRepoProvider = Provider<FavoritesRepo>((ref) => FavoritesRepo(ref.watch(dbProvider)));
final historyRepoProvider = Provider<HistoryRepo>((ref) => HistoryRepo(ref.watch(dbProvider)));
final ratingsRepoProvider = Provider<RatingsRepo>((ref) => RatingsRepo(ref.watch(dbProvider)));

final historyChangesProvider = StreamProvider<int>((ref) => ref.watch(audioHandlerProvider).historyChanges);

class LibraryData {
  const LibraryData({this.favorites = const [], this.history = const [], this.ratings = const []});
  final List<PostRef> favorites;
  final List<HistoryEntry> history;
  final List<RatedPost> ratings;

  bool isFavorite(int id) => favorites.any((p) => p.id == id);
  int ratingOf(int id) => ratings.where((r) => r.post.id == id).firstOrNull?.rating ?? 0;
}

class LibraryNotifier extends AsyncNotifier<LibraryData> {
  FavoritesRepo get _favorites => ref.read(favoritesRepoProvider);
  HistoryRepo get _history => ref.read(historyRepoProvider);
  RatingsRepo get _ratings => ref.read(ratingsRepoProvider);

  @override
  Future<LibraryData> build() async {
    ref.watch(historyChangesProvider); // the player records plays; re-read then
    final (favorites, history, ratings) = await (
      ref.watch(favoritesRepoProvider).list(),
      ref.watch(historyRepoProvider).list(),
      ref.watch(ratingsRepoProvider).list(),
    ).wait;
    return LibraryData(favorites: favorites, history: history, ratings: ratings);
  }

  Future<void> _reload() async {
    final (favorites, history, ratings) = await (_favorites.list(), _history.list(), _ratings.list()).wait;
    state = AsyncData(LibraryData(favorites: favorites, history: history, ratings: ratings));
  }

  Future<void> toggleFavorite(PostRef post) async {
    await _favorites.toggle(post);
    await _reload();
  }

  Future<void> setRating(PostRef post, int rating) async {
    await _ratings.set(post, rating);
    await _reload();
  }

  Future<void> removeFromHistory(int postId) async {
    await _history.remove(postId);
    await _reload();
  }

  Future<void> clearHistory() async {
    await _history.clear();
    await _reload();
  }
}

final libraryProvider = AsyncNotifierProvider<LibraryNotifier, LibraryData>(LibraryNotifier.new);
