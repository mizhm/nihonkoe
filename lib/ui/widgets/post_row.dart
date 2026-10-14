import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../logic/layout.dart';
import '../../state/posts.dart';
import '../l10n.dart';
import 'post_card.dart';
import 'skeleton.dart';

const _rowHeight = 232.0;
const _cardWidth = 160.0;

class PostRow extends ConsumerWidget {
  const PostRow({super.key, required this.title, required this.listKey, required this.seeAllPath});
  final String title;
  final PostListKey listKey;
  final String seeAllPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(postListProvider(listKey));
    final posts = async.value?.posts;
    if (posts != null && posts.isEmpty) return const SizedBox.shrink();
    final header = Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 4, 4),
      child: Row(
        children: [
          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
          IconButton(
            tooltip: context.l10n.commonSeeAll,
            icon: const Icon(Symbols.arrow_forward),
            onPressed: () => context.push(seeAllPath),
          ),
        ],
      ),
    );
    final Widget body;
    if (posts != null) {
      body = ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: posts.length.clamp(0, 15),
        itemBuilder: (_, i) => SizedBox(
          width: _cardWidth,
          child: PostCard(post: posts[i], layout: CardLayout.grid, tags: const []),
        ),
      );
    } else if (async.hasError) {
      body = Center(
        child: TextButton.icon(
          onPressed: () => ref.invalidate(postListProvider(listKey)),
          icon: const Icon(Symbols.refresh),
          label: Text(context.l10n.commonRetry),
        ),
      );
    } else {
      body = ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: List.generate(
          3,
          (_) => const Padding(padding: EdgeInsets.only(right: 12), child: Skeleton(width: _cardWidth - 12)),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [header, SizedBox(height: _rowHeight, child: body)],
    );
  }
}
