import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'api/models.dart';
import 'ui/l10n.dart';
import 'ui/links.dart';
import 'ui/screens/gallery.dart';
import 'ui/screens/home.dart';
import 'ui/screens/library.dart';
import 'ui/screens/post.dart';
import 'ui/screens/results.dart';
import 'ui/screens/search.dart';
import 'ui/screens/settings.dart';
import 'ui/widgets/mini_player.dart';

final _rootKey = GlobalKey<NavigatorState>();

/// Pushed inside whichever tab is open, so the navigation bar stays.
List<RouteBase> _detailRoutes() => [
      GoRoute(path: 'post/:id', builder: (_, s) => PostScreen(id: int.parse(s.pathParameters['id']!))),
      GoRoute(
        path: 'tag/:slug',
        builder: (_, s) => ResultsScreen(query: ListQuery.tag(s.pathParameters['slug']!), title: s.uri.queryParameters['name']),
      ),
      GoRoute(
        path: 'results',
        builder: (_, s) => ResultsScreen(
          query: queryFromParams(s.uri.queryParameters),
          sort: toListSort(s.uri.queryParameters['sort']),
          title: s.uri.queryParameters['title'],
        ),
      ),
    ];

StatefulShellBranch _branch(String path, Widget screen) =>
    StatefulShellBranch(routes: [GoRoute(path: path, builder: (_, _) => screen, routes: _detailRoutes())]);

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: _rootKey,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(shell: shell),
        branches: [
          _branch('/', const HomeScreen()),
          _branch('/search', const SearchScreen()),
          _branch('/library', const LibraryScreen()),
          _branch('/settings', const SettingsScreen()),
        ],
      ),
      GoRoute(
        path: '/gallery/:id',
        parentNavigatorKey: _rootKey,
        pageBuilder: (_, s) => CustomTransitionPage(
          child: GalleryScreen(
            id: int.parse(s.pathParameters['id']!),
            initialIndex: int.tryParse(s.uri.queryParameters['index'] ?? '') ?? 0,
          ),
          transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
        ),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    NavigationDestination destination(IconData icon, String label) => NavigationDestination(
          icon: Icon(icon),
          selectedIcon: Icon(icon, fill: 1),
          label: label,
        );
    return Scaffold(
      body: shell,
      bottomNavigationBar: keyboardOpen
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const MiniPlayer(),
                NavigationBar(
                  selectedIndex: shell.currentIndex,
                  // Tapping the open tab again returns to its first screen.
                  onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
                  destinations: [
                    destination(Symbols.explore, l.tabsHome),
                    destination(Symbols.search, l.tabsSearch),
                    destination(Symbols.library_music, l.tabsLibrary),
                    destination(Symbols.settings, l.tabsSettings),
                  ],
                ),
              ],
            ),
    );
  }
}
