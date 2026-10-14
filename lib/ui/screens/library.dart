import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

import '../../api/models.dart';
import '../../logic/format.dart';
import '../../logic/layout.dart';
import '../../logic/library.dart';
import '../../state/library.dart';
import '../../state/player.dart';
import '../../state/settings.dart';
import '../l10n.dart';
import '../feedback.dart';
import '../links.dart';
import '../sheets/post_actions.dart';
import '../widgets/cover.dart';
import '../widgets/message.dart';
import '../widgets/post_card.dart';

enum _Tab { favorites, history, rated }

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  _Tab _tab = _Tab.favorites;

  Future<void> _confirmClear() async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.libraryClearConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.commonCancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l.libraryClear)),
        ],
      ),
    );
    if (ok == true && mounted) await reportErrors(context, ref.read(libraryProvider.notifier).clearHistory());
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final library = ref.watch(libraryProvider);
    final data = library.value ?? const LibraryData();
    final layout = ref.watch(settingsProvider.select((s) => s.cardLayout));
    final body = library.hasError && !library.hasValue
        // A read failure must not pass for an empty library.
        ? SliverFillRemaining(
            hasScrollBody: false,
            child: Message(
              icon: Symbols.cloud_off,
              title: l.listErrorTitle,
              hint: l.listErrorHint,
              onRetry: () => ref.invalidate(libraryProvider),
            ),
          )
        : switch (_tab) {
            _Tab.favorites =>
              data.favorites.isEmpty
                  ? SliverFillRemaining(
                      hasScrollBody: false,
                      child: Message(
                        icon: Symbols.favorite,
                        title: l.libraryEmptyFavorites,
                        hint: l.libraryEmptyFavoritesHint,
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      sliver: SliverGrid.builder(
                        gridDelegate: layout == CardLayout.list
                            ? const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 1, mainAxisExtent: 112)
                            : SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: layout.columns,
                                childAspectRatio: layout == CardLayout.grid ? 0.82 : 0.95,
                              ),
                        itemCount: data.favorites.length,
                        itemBuilder: (_, i) =>
                            PostCard(post: refToSummary(data.favorites[i]), layout: layout, tags: const []),
                      ),
                    ),
            _Tab.history =>
              data.history.isEmpty
                  ? SliverFillRemaining(
                      hasScrollBody: false,
                      child: Message(icon: Symbols.history, title: l.libraryEmptyHistory),
                    )
                  : SliverList.list(
                      children: [
                        for (final section in groupHistory(data.history, ref.watch(todayProvider))) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                            child: Text(switch (section.group) {
                              HistoryGroup.today => l.libraryGroupToday,
                              HistoryGroup.yesterday => l.libraryGroupYesterday,
                              HistoryGroup.week => l.libraryGroupWeek,
                              HistoryGroup.older => l.libraryGroupOlder,
                            }, style: Theme.of(context).textTheme.labelLarge),
                          ),
                          for (final e in section.items)
                            _LibraryRow(post: e.post, meta: _playedAt(context, e, section.group), inHistory: true),
                        ],
                      ],
                    ),
            _Tab.rated =>
              data.ratings.isEmpty
                  ? SliverFillRemaining(
                      hasScrollBody: false,
                      child: Message(icon: Symbols.star, title: l.libraryEmptyRated, hint: l.libraryEmptyRatedHint),
                    )
                  : SliverList.list(
                      children: [
                        for (final r in data.ratings) _LibraryRow(post: r.post, meta: l.libraryStars(r.rating)),
                      ],
                    ),
          };
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.medium(
            title: Text(l.tabsLibrary),
            actions: [
              if (_tab == _Tab.history && data.history.isNotEmpty)
                TextButton(onPressed: _confirmClear, child: Text(l.libraryClear)),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: SegmentedButton<_Tab>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: _Tab.favorites, label: Text(l.libraryFavorites)),
                  ButtonSegment(value: _Tab.history, label: Text(l.libraryHistory)),
                  ButtonSegment(value: _Tab.rated, label: Text(l.libraryRated)),
                ],
                selected: {_tab},
                onSelectionChanged: (s) => setState(() => _tab = s.single),
              ),
            ),
          ),
          body,
        ],
      ),
    );
  }

  String _playedAt(BuildContext context, HistoryEntry e, HistoryGroup group) {
    final m = MaterialLocalizations.of(context);
    final date = DateTime.fromMillisecondsSinceEpoch(e.playedAt);
    return switch (group) {
      HistoryGroup.today || HistoryGroup.yesterday => m.formatTimeOfDay(
        TimeOfDay.fromDateTime(date),
        alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
      ),
      HistoryGroup.week => m.formatShortMonthDay(date),
      HistoryGroup.older => m.formatShortDate(date),
    };
  }
}

class _LibraryRow extends ConsumerWidget {
  const _LibraryRow({required this.post, required this.meta, this.inHistory = false});
  final PostRef post;
  final String meta;
  final bool inHistory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final resume = ref.watch(inProgressProvider(post.id)).value;
    final line = [?post.cv, meta].join(' · ');
    return ListTile(
      leading: SizedBox(
        width: 64,
        child: Cover(url: post.cover, aspectRatio: 4 / 3, borderRadius: BorderRadius.circular(10)),
      ),
      title: Text(post.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(line, maxLines: 1, overflow: TextOverflow.ellipsis),
          if (resume != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l.libraryInProgress(formatTime(resume.seconds)),
                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary),
              ),
            ),
        ],
      ),
      onTap: () => context.push(postPath(branchBase(context), post.id)),
      onLongPress: () => showPostActions(context, post, inHistory: inHistory),
    );
  }
}
