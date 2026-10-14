import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/models.dart';
import '../logic/posts.dart';
import '../logic/tags.dart';
import 'core.dart';

typedef PostListKey = ({ListQuery query, ListSort sort});

const latestKey = (query: ListQuery.latest(), sort: ListSort.newest);

@immutable
class PostListState {
  const PostListState({
    required this.posts,
    required this.page,
    required this.hasNext,
    this.featured = const [],
    this.loadingMore = false,
    this.loadMoreError,
  });
  final List<PostSummary> posts;
  final int page;
  final bool hasNext;
  final List<FeaturedPost> featured;
  final bool loadingMore;
  final Object? loadMoreError;

  PostListState _with({required bool loadingMore, Object? loadMoreError}) => PostListState(
      posts: posts, page: page, hasNext: hasNext, featured: featured, loadingMore: loadingMore, loadMoreError: loadMoreError);
}

class PostListNotifier extends AsyncNotifier<PostListState> {
  PostListNotifier(this.key);
  final PostListKey key;

  // The notifier outlives a refresh, so a page requested before it must not land after it.
  int _generation = 0;

  @override
  Future<PostListState> build() async {
    _generation++;
    ref.cacheFor(const Duration(minutes: 30));
    final first = await ref.watch(apiClientProvider).listPosts(key.query, sort: key.sort);
    return PostListState(posts: uniqueById(first.items), page: 1, hasNext: first.hasNext, featured: first.featured);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (state.isLoading || current == null || !current.hasNext || current.loadingMore) return;
    final generation = _generation;
    state = AsyncData(current._with(loadingMore: true));
    try {
      final next = await ref.read(apiClientProvider).listPosts(key.query, page: current.page + 1, sort: key.sort);
      if (!ref.mounted || generation != _generation) return;
      state = AsyncData(PostListState(
        // New uploads shift pagination, so a later page can repeat earlier posts.
        posts: uniqueById([...current.posts, ...next.items]),
        page: next.page,
        hasNext: next.hasNext,
        featured: current.featured,
      ));
    } catch (error) {
      if (!ref.mounted || generation != _generation) return;
      state = AsyncData(current._with(loadingMore: false, loadMoreError: error));
    }
  }
}

final postListProvider =
    AsyncNotifierProvider.autoDispose.family<PostListNotifier, PostListState, PostListKey>(PostListNotifier.new);

final postProvider = FutureProvider.autoDispose.family<PostDetail?, int>((ref, id) {
  ref.cacheFor(const Duration(minutes: 30));
  return ref.watch(apiClientProvider).getPost(id);
});

final featuredProvider = FutureProvider.autoDispose<List<FeaturedPost>>(
  (ref) async => (await ref.watch(postListProvider(latestKey).future)).featured,
);

final tagIndexProvider = FutureProvider.family<List<TagIndexItem>, TagIndex>((ref, index) async {
  final dir = await ref.watch(cacheDirProvider.future);
  final file = File('${dir.path}/tag-index-${index.name}.json');
  final now = DateTime.now().millisecondsSinceEpoch;
  final cached = parseTagCache(await file.exists() ? await file.readAsString() : null, now);
  if (cached != null) return cached.items;
  final items = buildTagIndex(await ref.watch(apiClientProvider).listTagIndex(index));
  if (items.isNotEmpty) await file.writeAsString(encodeTagCache(now, items));
  return items;
});

final tagNamerProvider = Provider.autoDispose<TagNamer>((ref) => makeTagNamer(
      ref.watch(tagIndexProvider(TagIndex.tags)).value,
      ref.watch(tagIndexProvider(TagIndex.cv)).value,
    ));
