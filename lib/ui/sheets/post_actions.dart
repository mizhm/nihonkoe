import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../api/models.dart';
import '../../logic/queue.dart';
import '../../player/handler.dart';
import '../../state/library.dart';
import '../../state/player.dart';
import '../../state/posts.dart';
import '../l10n.dart';
import '../feedback.dart';
import '../links.dart';
import '../widgets/cover.dart';

Future<void> showPostActions(BuildContext context, PostRef post, {bool inHistory = false}) {
  HapticFeedback.mediumImpact();
  final base = branchBase(context); // read before the sheet: its route is outside the shell
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => PostActionsSheet(post: post, base: base, inHistory: inHistory),
  );
}

class PostActionsSheet extends ConsumerStatefulWidget {
  const PostActionsSheet({super.key, required this.post, required this.base, this.inHistory = false});
  final PostRef post;
  final String base;
  final bool inHistory; // opened from the History tab: offer "Remove from history"

  @override
  ConsumerState<PostActionsSheet> createState() => _PostActionsSheetState();
}

class _PostActionsSheetState extends ConsumerState<PostActionsSheet> {
  bool _loadingTags = false;
  List<Term>? _tags;
  bool _tagsFailed = false;
  String? _loadingAction;

  /// Loads the work's streams and where it was left, then runs [action]; a work without audio says so.
  Future<void> _withItems(String label, _PlayAction action, {String? done}) async {
    final messenger = ScaffoldMessenger.of(context);
    final l = context.l10n;
    // Read now: the sheet closes before the action runs, and its ref goes with it.
    final handler = ref.read(audioHandlerProvider);
    final positions = ref.read(positionsRepoProvider);
    setState(() => _loadingAction = label);
    try {
      final detail = await ref.read(postProvider(widget.post.id).future);
      final items = detail == null ? const <QueueItem>[] : queueItemsFor(detail);
      final resume = await positions.inProgress(widget.post.id);
      if (!mounted) return;
      Navigator.pop(context);
      if (items.isEmpty) {
        messenger.showSnackBar(SnackBar(content: Text(l.detailNoStream)));
        return;
      }
      await action(handler, items, resume?.stream ?? 0);
      if (done != null) messenger.showSnackBar(SnackBar(content: Text(done)));
    } catch (_) {
      if (mounted) setState(() => _loadingAction = null);
      messenger.showSnackBar(SnackBar(content: Text(l.listErrorTitle)));
    }
  }

  Widget _playTile(IconData icon, String label, _PlayAction action, {String? done}) => ListTile(
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
              leading: SizedBox.square(
                dimension: 48,
                child: Cover(url: post.cover, borderRadius: BorderRadius.circular(8)),
              ),
              title: Text(post.title, maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: post.cv == null ? null : Text(post.cv!),
            ),
            const Divider(),
            _playTile(Symbols.play_arrow, l.actionsPlayNow, (h, items, start) => h.playItems(items, start: start)),
            _playTile(
              Symbols.playlist_play,
              l.actionsPlayNext,
              (h, items, _) => h.playNextItems(items),
              done: l.queueNext,
            ),
            _playTile(Symbols.queue_music, l.detailAddToQueue, (h, items, _) => h.enqueue(items), done: l.queueAdded),
            Consumer(
              builder: (context, ref, _) {
                final favorite = ref.watch(libraryProvider).value?.isFavorite(post.id) ?? false;
                return ListTile(
                  leading: Icon(Symbols.favorite, fill: favorite ? 1 : 0),
                  title: Text(favorite ? l.detailUnfavorite : l.detailFavorite),
                  onTap: () {
                    final library = ref.read(libraryProvider.notifier);
                    final saving = reportErrors(context, library.toggleFavorite(post)); // binds the messenger first
                    Navigator.pop(context);
                    saving.ignore();
                  },
                );
              },
            ),
            const Divider(),
            if (post.circle case final circle?)
              ListTile(
                leading: const Icon(Symbols.groups),
                title: Text(l.actionsViewCircle),
                subtitle: Text(circle),
                onTap: () => _go(resultsPath(widget.base, ListQuery.search(circle), title: circle)),
              ),
            for (final cv in post.cv?.split(RegExp(r'\s*[,、]\s*')) ?? const <String>[])
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
              trailing: _loadingTags
                  ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : null,
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
            if (widget.inHistory)
              ListTile(
                leading: const Icon(Symbols.history_toggle_off),
                title: Text(l.actionsRemoveFromHistory),
                onTap: () {
                  final library = ref.read(libraryProvider.notifier);
                  final removing = reportErrors(context, library.removeFromHistory(post.id));
                  Navigator.pop(context);
                  removing.ignore();
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// [start] is the stream to begin with: the part the listener left, or 0.
typedef _PlayAction = Future<void> Function(NihonkoeAudioHandler handler, List<QueueItem> items, int start);
