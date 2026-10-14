import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../api/models.dart';
import '../../l10n/app_localizations.dart';
import '../../logic/layout.dart';
import '../../state/posts.dart';
import '../../state/settings.dart';
import '../l10n.dart';
import '../sheets/sort.dart';
import '../widgets/featured_carousel.dart';
import '../widgets/post_grid.dart';

const _layoutIcons = {CardLayout.grid: Symbols.grid_view, CardLayout.compact: Symbols.apps, CardLayout.list: Symbols.view_list};

const _feedIcons = {
  HomeFeed.latest: Symbols.new_releases,
  HomeFeed.hotWeek: Symbols.local_fire_department,
  HomeFeed.hotMonth: Symbols.trending_up,
  HomeFeed.requested: Symbols.front_hand,
  HomeFeed.maniax: Symbols.explicit,
};

String _feedName(AppLocalizations l, HomeFeed feed) => switch (feed) {
      HomeFeed.latest => l.homeLatest,
      HomeFeed.hotWeek => l.homeHotWeek,
      HomeFeed.hotMonth => l.homeHotMonth,
      HomeFeed.requested => l.feedRequested,
      HomeFeed.maniax => l.feedManiax,
    };

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final feed = settings.homeFeed;
    final feedKey = (query: feed.query, sort: feed.fixedSort ?? settings.homeSort);
    final layoutNames = {CardLayout.grid: l.layoutGrid, CardLayout.compact: l.layoutCompact, CardLayout.list: l.layoutList};

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          // Only this screen's lists: other tabs may be deep into their own pages.
          ref.invalidate(postListProvider(feedKey));
          if (feed == HomeFeed.latest) ref.invalidate(postListProvider(latestKey)); // featured comes from here
          // The tag index is kept for the session; a launch while the site was down would otherwise stick.
          for (final index in TagIndex.values) {
            if (ref.read(tagIndexProvider(index)).hasError) ref.invalidate(tagIndexProvider(index));
          }
          try {
            await ref.read(postListProvider(feedKey).future);
          } catch (_) {
            // The old posts stay on screen, so say the refresh itself failed.
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.listRefreshFailed)));
            }
          }
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              titleSpacing: 12,
              title: _Capsule(
                child: MenuAnchor(
                  menuChildren: [
                    for (final f in HomeFeed.values)
                      MenuItemButton(
                        leadingIcon: Icon(_feedIcons[f], fill: f == feed ? 1 : 0),
                        trailingIcon: f == feed ? const Icon(Symbols.check) : null,
                        onPressed: () => notifier.setHomeFeed(f),
                        child: Text(_feedName(l, f)),
                      ),
                  ],
                  builder: (context, menu, _) => Tooltip(
                    message: l.homeFeedPick,
                    child: InkWell(
                      customBorder: const StadiumBorder(),
                      onTap: () => menu.isOpen ? menu.close() : menu.open(),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_feedIcons[feed], size: 20, fill: 1, color: scheme.primary),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(_feedName(l, feed),
                                  overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
                            ),
                            const Icon(Symbols.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                _Capsule(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: l.sortHeading,
                        icon: Icon(Symbols.sort, color: feed.fixedSort == null ? null : scheme.onSurface.withValues(alpha: 0.38)),
                        onPressed: () async {
                          if (feed.fixedSort != null) {
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(SnackBar(content: Text(l.sortFixedHot)));
                            return;
                          }
                          final sort = await showSortSheet(context, settings.homeSort);
                          if (sort != null) notifier.setHomeSort(sort);
                        },
                      ),
                      IconButton(
                        tooltip: l.layoutSwitch(layoutNames[settings.cardLayout.next]!),
                        icon: Icon(_layoutIcons[settings.cardLayout]),
                        onPressed: notifier.cycleCardLayout,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
            if (feed == HomeFeed.latest) const SliverToBoxAdapter(child: FeaturedCarousel()),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            PostSliverGrid(listKey: feedKey),
          ],
        ),
      ),
    );
  }
}

/// A rounded tonal pill holding toolbar controls, as KikoFlu's feed toolbar does.
class _Capsule extends StatelessWidget {
  const _Capsule({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Material(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: child,
      );
}
