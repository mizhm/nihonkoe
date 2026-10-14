import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../api/models.dart';
import '../../logic/format.dart';
import '../../logic/queue.dart';
import '../../state/player.dart';
import '../../state/posts.dart';
import '../l10n.dart';
import '../links.dart';
import '../widgets/cover.dart';
import '../widgets/message.dart';
import '../widgets/skeleton.dart';

class PostScreen extends ConsumerWidget {
  const PostScreen({super.key, required this.id});
  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return Scaffold(
      body: ref.watch(postProvider(id)).when(
            loading: () => const _DetailSkeleton(),
            error: (_, _) => Scaffold(
              appBar: AppBar(),
              body: Message(
                icon: Symbols.cloud_off,
                title: l.detailLoadFailed,
                hint: l.listErrorHint,
                onRetry: () => ref.invalidate(postProvider(id)),
              ),
            ),
            data: (post) => post == null
                ? Scaffold(appBar: AppBar(), body: Message(icon: Symbols.search_off, title: l.detailNotFound))
                : _PostBody(post: post),
          ),
    );
  }
}

class _PostBody extends ConsumerWidget {
  const _PostBody({required this.post});
  final PostDetail post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final base = branchBase(context);
    final items = queueItemsFor(post);
    final handler = ref.read(audioHandlerProvider);
    final resumeAt = ref.watch(inProgressProvider(post.id)).value;
    Widget section(String title) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(title, style: theme.textTheme.titleMedium),
        );
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          actions: [
            IconButton(
              tooltip: l.actionsOpenWeb,
              icon: const Icon(Symbols.open_in_new),
              onPressed: () => launchUrl(Uri.parse(post.url), mode: LaunchMode.externalApplication),
            ),
          ],
        ),
        SliverList.list(
          children: [
            if (post.images.isEmpty)
              Cover(url: post.cover, aspectRatio: 4 / 3)
            else
              Semantics(
                label: l.detailOpenImage(1),
                button: true,
                child: InkWell(
                  onTap: () => context.push(galleryPath(post.id, 0)),
                  child: Cover(url: post.cover, aspectRatio: 4 / 3),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: SelectableText(post.title, style: theme.textTheme.titleLarge),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (post.circle case final circle?)
                    ActionChip(
                      avatar: const Icon(Symbols.groups),
                      label: Text(circle),
                      onPressed: () => context.push(resultsPath(base, ListQuery.search(circle), title: circle)),
                    ),
                  if (post.cv case final cv?)
                    ActionChip(
                      avatar: const Icon(Symbols.record_voice_over),
                      label: Text(cv),
                      onPressed: () => context.push(resultsPath(base, ListQuery.search(cv), title: cv)),
                    ),
                  if (post.rjCode case final rj?) Chip(label: Text(rj)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: items.isEmpty ? null : () => handler.playItems(items),
                      icon: const Icon(Symbols.play_arrow),
                      label: Text(resumeAt == null ? l.detailPlay : l.detailResume(formatTime(resumeAt))),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: items.isEmpty
                          ? null
                          : () {
                              handler.enqueue(items);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.queueAdded)));
                            },
                      icon: const Icon(Symbols.queue_music),
                      label: Text(l.detailAddToQueue),
                    ),
                  ),
                ],
              ),
            ),
            if (post.streams.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(l.detailNoStream, style: theme.textTheme.bodySmall),
              ),
            if (post.downloadUrl case final url?)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: OutlinedButton.icon(
                  onPressed: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
                  icon: const Icon(Symbols.download),
                  label: Text(l.detailDownload),
                ),
              ),
            if (post.tracks.isNotEmpty) ...[
              section(l.detailChapters(post.tracks.length)),
              for (final track in post.tracks)
                ListTile(
                  dense: true,
                  enabled: items.isNotEmpty,
                  leading: Text(formatTime(track.startSeconds), style: theme.textTheme.labelMedium),
                  title: Text(track.title),
                  onTap: () => handler.playItems(items, startAt: Duration(seconds: track.startSeconds)),
                ),
            ],
            if (post.tags.isNotEmpty) ...[
              section(l.detailTags),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final tag in post.tags)
                      ActionChip(label: Text(tag.name), onPressed: () => context.push(tagPath(base, tag.slug, tag.name))),
                  ],
                ),
              ),
            ],
            if (post.images.isNotEmpty) ...[
              section(l.detailImages),
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: post.images.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => Tooltip(
                    message: l.detailOpenImage(i + 1),
                    child: InkWell(
                      onTap: () => context.push(galleryPath(post.id, i)),
                      child: SizedBox(width: 160, child: Cover(url: post.images[i], borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                ),
              ),
            ],
            SizedBox(height: 32 + MediaQuery.paddingOf(context).bottom),
          ],
        ),
      ],
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            AspectRatio(aspectRatio: 4 / 3, child: Skeleton()),
            SizedBox(height: 16),
            Skeleton(height: 24),
            SizedBox(height: 8),
            Skeleton(height: 24, width: 200),
            SizedBox(height: 16),
            Skeleton(height: 40),
          ],
        ),
      );
}
