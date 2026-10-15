import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/models.dart';
import '../../state/posts.dart';
import '../l10n.dart';
import '../links.dart';
import '../sheets/post_actions.dart';
import 'cover.dart';

const _itemExtent = 320.0;

class FeaturedCarousel extends ConsumerWidget {
  const FeaturedCarousel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featured = ref.watch(featuredProvider).value ?? const [];
    // The site widget can disappear or be renamed; then the block simply isn't shown.
    if (featured.isEmpty) return const SizedBox.shrink();
    final base = branchBase(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(context.l10n.homeFeatured, style: Theme.of(context).textTheme.titleLarge),
        ),
        SizedBox(
          height: 220,
          child: CarouselView(
            itemExtent: _itemExtent,
            shrinkExtent: 200,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            enableSplash: false,
            children: [for (final post in featured) _FeaturedItem(key: ValueKey('featured-${post.id}'), post: post, base: base)],
          ),
        ),
      ],
    );
  }
}

class _FeaturedItem extends ConsumerWidget {
  const _FeaturedItem({super.key, required this.post, required this.base});
  final FeaturedPost post;
  final String base;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The widget only has id + cover; the title arrives with the (cached) post detail.
    final detail = ref.watch(postProvider(post.id)).value;
    final postRef = detail != null ? PostRef.fromDetail(detail) : PostRef(id: post.id, title: '', cover: post.cover);
    final item = InkWell(
      onTap: () => context.push(postPath(base, post.id)),
      onLongPress: () => showPostActions(context, postRef),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Cover(url: post.cover),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black87],
                stops: [0.5, 1],
              ),
            ),
          ),
          if (detail != null)
            // Fixed width: the carousel squeezes items while swiping, and a stretching title would reflow every frame.
            Positioned(
              left: 12,
              bottom: 12,
              width: _itemExtent - 24,
              child: Text(
                detail.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white),
              ),
            ),
        ],
      ),
    );
    // The widget only has a cover until the detail arrives; never leave the item unnamed.
    return Semantics(label: detail?.title ?? context.l10n.homeFeatured, button: true, child: item);
  }
}
