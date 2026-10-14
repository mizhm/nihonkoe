import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../api/models.dart';
import '../../logic/queue.dart';
import '../../state/player.dart';
import '../../state/posts.dart';
import '../l10n.dart';
import '../links.dart';
import '../widgets/cover.dart';

Future<void> showPostActions(BuildContext context, PostRef post) {
  HapticFeedback.mediumImpact();
  final base = branchBase(context); // read before the sheet: its route is outside the shell
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => PostActionsSheet(post: post, base: base),
  );
}

class PostActionsSheet extends ConsumerStatefulWidget {
  const PostActionsSheet({super.key, required this.post, required this.base});
  final PostRef post;
  final String base;

  @override
  ConsumerState<PostActionsSheet> createState() => _PostActionsSheetState();
}

class _PostActionsSheetState extends ConsumerState<PostActionsSheet> {
  bool _loadingTags = false;
  List<Term>? _tags;
  bool _tagsFailed = false;
  String? _loadingAction;

  /// Loads the work's streams, then runs [action]; a work without audio says so.
  Future<void> _withItems(String label, Future<void> Function(List<QueueItem> items) action, {String? done}) async {
    final messenger = ScaffoldMessenger.of(context);
    final l = context.l10n;
    setState(() => _loadingAction = label);
    try {
      final detail = await ref.read(postProvider(widget.post.id).future);
      final items = detail == null ? const <QueueItem>[] : queueItemsFor(detail);
      if (!mounted) return;
      Navigator.pop(context);
      if (items.isEmpty) {
        messenger.showSnackBar(SnackBar(content: Text(l.detailNoStream)));
        return;
      }
      await action(items);
      if (done != null) messenger.showSnackBar(SnackBar(content: Text(done)));
    } catch (_) {
      if (mounted) setState(() => _loadingAction = null);
      messenger.showSnackBar(SnackBar(content: Text(l.listErrorTitle)));
    }
  }

  Widget _playTile(IconData icon, String label, Future<void> Function(List<QueueItem>) action, {String? done}) => ListTile(
        leading: Icon(icon),
        title: Text(label),
        trailing: _loadingAction == label
            ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : null,
        onTap: _loadingAction != null ? null : () => _withItems(label, action, done: done),
      );

  void _go(String path) {
    final router = GoRouter.of(context);
    Navigator.pop(context);
    router.push(path);
  }

  Future<void> _loadTags() async {
    setState(() {
      _loadingTags = true;
      _tagsFailed = false;
    });
    try {
      final detail = await ref.read(postProvider(widget.post.id).future);
      if (!mounted) return;
      setState(() => _tags = detail?.tags ?? const []);
    } catch (_) {
      if (mounted) setState(() => _tagsFailed = true);
    } finally {
      if (mounted) setState(() => _loadingTags = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final post = widget.post;
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: SizedBox.square(dimension: 48, child: Cover(url: post.cover, borderRadius: BorderRadius.circular(8))),
              title: Text(post.title, maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: post.cv == null ? null : Text(post.cv!),
            ),
            const Divider(),
            _playTile(Symbols.play_arrow, l.actionsPlayNow, (items) => ref.read(audioHandlerProvider).playItems(items)),
            _playTile(Symbols.playlist_play, l.actionsPlayNext, (items) => ref.read(audioHandlerProvider).playNextItems(items),
                done: l.queueNext),
            _playTile(Symbols.queue_music, l.detailAddToQueue, (items) => ref.read(audioHandlerProvider).enqueue(items),
                done: l.queueAdded),
            // Favorites arrive with the library (phase 3).
            ListTile(leading: const Icon(Symbols.favorite), title: Text(l.detailFavorite), enabled: false),
            const Divider(),
            if (post.circle case final circle?)
              ListTile(
                leading: const Icon(Symbols.groups),
                title: Text(l.actionsViewCircle),
                subtitle: Text(circle),
                onTap: () => _go(resultsPath(widget.base, ListQuery.search(circle), title: circle)),
              ),
            if (post.cv case final cv?)
              ListTile(
                leading: const Icon(Symbols.record_voice_over),
                title: Text(l.actionsViewCv),
                subtitle: Text(cv),
                onTap: () => _go(resultsPath(widget.base, ListQuery.search(cv), title: cv)),
              ),
            ListTile(
              leading: const Icon(Symbols.sell),
              title: Text(l.actionsViewTags),
              subtitle: _tagsFailed ? Text(l.listErrorTitle) : null,
              trailing: _loadingTags ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)) : null,
              onTap: _loadingTags ? null : _loadTags,
            ),
            if (_tags case final tags? when tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final tag in tags)
                      ActionChip(label: Text(tag.name), onPressed: () => _go(tagPath(widget.base, tag.slug, tag.name))),
                  ],
                ),
              ),
            ListTile(
              leading: const Icon(Symbols.share),
              title: Text(l.actionsShare),
              onTap: () {
                Navigator.pop(context);
                SharePlus.instance.share(ShareParams(text: post.url));
              },
            ),
            ListTile(
              leading: const Icon(Symbols.open_in_new),
              title: Text(l.actionsOpenWeb),
              onTap: () {
                Navigator.pop(context);
                launchUrl(Uri.parse(post.url), mode: LaunchMode.externalApplication);
              },
            ),
          ],
        ),
      ),
    );
  }
}
