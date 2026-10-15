import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../api/models.dart';
import '../../logic/layout.dart';
import '../links.dart';
import '../sheets/post_actions.dart';
import 'cover.dart';

const coverRatio = 4 / 3;

class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.post, required this.layout, required this.tags});
  final PostSummary post;
  final CardLayout layout;
  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final radius = BorderRadius.circular(layout == CardLayout.compact ? 8 : 12);
    final cover = Stack(
      children: [
        Cover(url: post.cover, aspectRatio: coverRatio, borderRadius: radius),
        if (post.nsfw)
          Positioned(
            top: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: theme.colorScheme.error, borderRadius: BorderRadius.circular(6)),
              child: Text('R18', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onError)),
            ),
          ),
      ],
    );
    // One row only: grid cells have a fixed height, so a wrapped second row would spill onto the next card.
    final chips = Row(
      children: [
        for (final (i, tag) in tags.indexed)
          Flexible(
            child: Container(
              margin: EdgeInsets.only(left: i == 0 ? 0 : 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: theme.colorScheme.secondaryContainer, borderRadius: BorderRadius.circular(6)),
              child: Text(
                tag,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSecondaryContainer),
              ),
            ),
          ),
      ],
    );
    final texts = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(post.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall),
        if (layout != CardLayout.compact && post.cv != null)
          Text(post.cv!, maxLines: 1, overflow: TextOverflow.ellipsis, style: muted),
        if (tags.isNotEmpty) ...[const SizedBox(height: 4), chips],
      ],
    );
    return InkWell(
      borderRadius: radius,
      onTap: () => context.push(postPath(branchBase(context), post.id)),
      onLongPress: () => showPostActions(context, PostRef.fromSummary(post)),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: layout == CardLayout.list
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [SizedBox(width: 120, child: cover), const SizedBox(width: 12), Expanded(child: texts)],
              )
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [cover, const SizedBox(height: 6), texts]),
      ),
    );
  }
}
