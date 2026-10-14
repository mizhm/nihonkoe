import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../api/models.dart';
import '../../logic/layout.dart';
import '../../state/posts.dart';
import '../../state/settings.dart';
import '../l10n.dart';
import '../links.dart';
import '../sheets/sort.dart';
import '../widgets/featured_carousel.dart';
import '../widgets/post_grid.dart';
import '../widgets/post_row.dart';

const _feeds = [ListQuery.latest(), ListQuery.category('requested'), ListQuery.category('rating/maniax')];

const _layoutIcons = {CardLayout.grid: Symbols.grid_view, CardLayout.compact: Symbols.apps, CardLayout.list: Symbols.view_list};

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _feed = 0;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final settings = ref.watch(settingsProvider);
    final base = branchBase(context);
    final feedKey = (query: _feeds[_feed], sort: settings.homeSort);
    const hotWeek = (query: ListQuery.latest(), sort: ListSort.popularWeek);
    const hotMonth = (query: ListQuery.latest(), sort: ListSort.popularMonth);
    const requested = (query: ListQuery.category('requested'), sort: ListSort.newest);
    final layoutNames = {CardLayout.grid: l.layoutGrid, CardLayout.compact: l.layoutCompact, CardLayout.list: l.layoutList};

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          // Only this screen's lists: other tabs may be deep into their own pages.
          for (final key in {latestKey, hotWeek, hotMonth, requested, feedKey}) {
            ref.invalidate(postListProvider(key));
          }
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
            SliverAppBar.medium(title: Text(l.tabsHome)),
            const SliverToBoxAdapter(child: FeaturedCarousel()),
            SliverToBoxAdapter(
              child: PostRow(
                title: l.homeHotWeek,
                listKey: hotWeek,
                seeAllPath: resultsPath(base, hotWeek.query, sort: hotWeek.sort, title: l.homeHotWeek),
              ),
            ),
            SliverToBoxAdapter(
              child: PostRow(
                title: l.homeHotMonth,
                listKey: hotMonth,
                seeAllPath: resultsPath(base, hotMonth.query, sort: hotMonth.sort, title: l.homeHotMonth),
              ),
            ),
            SliverToBoxAdapter(
              child: PostRow(
                title: l.feedRequested,
                listKey: requested,
                seeAllPath: resultsPath(base, requested.query, title: l.feedRequested),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.homeLatest, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SegmentedButton<int>(
                              showSelectedIcon: false,
                              segments: [
                                ButtonSegment(value: 0, label: Text(l.feedLatest)),
                                ButtonSegment(value: 1, label: Text(l.feedRequested)),
                                ButtonSegment(value: 2, label: Text(l.feedManiax)),
                              ],
                              selected: {_feed},
                              onSelectionChanged: (s) => setState(() => _feed = s.single),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: l.sortHeading,
                          icon: const Icon(Symbols.sort),
                          onPressed: () async {
                            final sort = await showSortSheet(context, settings.homeSort);
                            if (sort != null) ref.read(settingsProvider.notifier).setHomeSort(sort);
                          },
                        ),
                        IconButton(
                          tooltip: l.layoutSwitch(layoutNames[settings.cardLayout.next]!),
                          icon: Icon(_layoutIcons[settings.cardLayout]),
                          onPressed: ref.read(settingsProvider.notifier).cycleCardLayout,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            PostSliverGrid(listKey: feedKey),
          ],
        ),
      ),
    );
  }
}
