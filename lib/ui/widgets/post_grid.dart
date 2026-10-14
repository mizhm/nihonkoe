import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../logic/layout.dart';
import '../../state/posts.dart';
import '../../state/settings.dart';
import '../l10n.dart';
import 'message.dart';
import 'post_card.dart';
import 'skeleton.dart';

/// Starts fetching the next page this many cards before the end.
const _prefetch = 6;

class PostSliverGrid extends ConsumerWidget {
  const PostSliverGrid({super.key, required this.listKey});
  final PostListKey listKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final layout = ref.watch(settingsProvider.select((s) => s.cardLayout));
    final namer = ref.watch(tagNamerProvider);
    final async = ref.watch(postListProvider(listKey));
    final provider = postListProvider(listKey);

    return switch (async) {
      AsyncValue(:final value?) when value.posts.isEmpty =>
        SliverFillRemaining(hasScrollBody: false, child: Message(icon: Symbols.search_off, title: l.listEmpty)),
      AsyncValue(:final value?) => SliverMainAxisGroup(slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            sliver: SliverGrid.builder(
              gridDelegate: layout == CardLayout.list
                  ? const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 1, mainAxisExtent: 112)
                  : SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: layout.columns, childAspectRatio: layout == CardLayout.grid ? 0.82 : 0.95),
              itemCount: value.posts.length,
              itemBuilder: (context, i) {
                if (i >= value.posts.length - _prefetch && value.hasNext && !value.loadingMore && value.loadMoreError == null) {
                  // Read now: the callback may run after this widget is gone, and the notifier guards itself.
                  final notifier = ref.read(provider.notifier);
                  WidgetsBinding.instance.addPostFrameCallback((_) => notifier.loadMore());
                }
                final post = value.posts[i];
                return PostCard(post: post, layout: layout, tags: namer(post.tagSlugs, layout.tags));
              },
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: value.loadingMore
                    ? const CircularProgressIndicator()
                    : value.loadMoreError != null
                        ? FilledButton.tonal(onPressed: () => ref.read(provider.notifier).loadMore(), child: Text(l.listLoadMore))
                        : const SizedBox.shrink(),
              ),
            ),
          ),
        ]),
      AsyncValue(hasError: true) => SliverFillRemaining(
          hasScrollBody: false,
          child: Message(
            icon: Symbols.cloud_off,
            title: l.listErrorTitle,
            hint: l.listErrorHint,
            onRetry: () => ref.invalidate(provider),
          ),
        ),
      _ => SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid.count(
            crossAxisCount: layout.columns,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: layout == CardLayout.list ? 3 : 0.82,
            children: List.generate(6, (_) => const Skeleton()),
          ),
        ),
    };
  }
}
