import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nihonkoe/api/models.dart';
import 'package:nihonkoe/app.dart';

import '../helpers.dart';
import '../player_fakes.dart';

Future<void> openLibrary(WidgetTester tester, {MemoryFavorites? favorites, MemoryHistory? history, MemoryRatings? ratings, MemoryPositions? positions}) async {
  final h = history ?? MemoryHistory();
  await tester.pumpWidget(ProviderScope(
    overrides: await testOverrides(
      favorites: favorites,
      history: h,
      ratings: ratings,
      positions: positions,
      handler: makeHandler(history: h, positions: positions),
    ),
    retry: noRetry,
    child: const NihonkoeApp(),
  ));
  await tester.pumpAndSettle();
  await tester.tap(find.text(en.tabsLibrary));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('empty states for each tab', (tester) async {
    await openLibrary(tester);
    expect(find.text(en.libraryEmptyFavorites), findsOneWidget);
    await tester.tap(find.text(en.libraryHistory));
    await tester.pumpAndSettle();
    expect(find.text(en.libraryEmptyHistory), findsOneWidget);
    await tester.tap(find.text(en.libraryRated));
    await tester.pumpAndSettle();
    expect(find.text(en.libraryEmptyRated), findsOneWidget);
  });

  testWidgets('favorites show as cards that open the post', (tester) async {
    final favorites = MemoryFavorites();
    await favorites.toggle(const PostRef(id: 5, title: 'Fav work'));
    await openLibrary(tester, favorites: favorites);
    expect(find.text('Fav work'), findsOneWidget);
    await tester.tap(find.text('Fav work'));
    await tester.pumpAndSettle();
    expect(find.text(en.detailNotFound), findsOneWidget); // mock HTTP 404s the post page
  });

  testWidgets('history is grouped, shows the in-progress badge and can be cleared after confirming', (tester) async {
    final history = MemoryHistory();
    await history.recordPlay(const PostRef(id: 1, title: 'Heard today'));
    final positions = MemoryPositions()..values['1:0'] = 754;
    await openLibrary(tester, history: history, positions: positions);
    await tester.tap(find.text(en.libraryHistory));
    await tester.pumpAndSettle();
    expect(find.text(en.libraryGroupToday), findsOneWidget);
    expect(find.text('Heard today'), findsOneWidget);
    expect(find.text(en.libraryInProgress('12:34')), findsOneWidget);
    await tester.tap(find.text(en.libraryClear));
    await tester.pumpAndSettle();
    expect(find.text(en.libraryClearConfirm), findsOneWidget);
    await tester.tap(find.text(en.commonCancel));
    await tester.pumpAndSettle();
    expect(find.text('Heard today'), findsOneWidget);
    await tester.tap(find.text(en.libraryClear));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, en.libraryClear));
    await tester.pumpAndSettle();
    expect(find.text(en.libraryEmptyHistory), findsOneWidget);
    expect(positions.values['1:0'], 754, reason: 'clearing history keeps the listening position');
  });

  testWidgets('rated works list best first with their stars; long-press in history offers removal', (tester) async {
    final ratings = MemoryRatings();
    await ratings.set(const PostRef(id: 1, title: 'Good'), 3);
    await ratings.set(const PostRef(id: 2, title: 'Best'), 5);
    final history = MemoryHistory();
    await history.recordPlay(const PostRef(id: 3, title: 'Played'));
    await openLibrary(tester, ratings: ratings, history: history);
    await tester.tap(find.text(en.libraryRated));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('Best')).dy, lessThan(tester.getTopLeft(find.text('Good')).dy));
    expect(find.textContaining(en.libraryStars(5)), findsOneWidget);
    await tester.tap(find.text(en.libraryHistory));
    await tester.pumpAndSettle();
    await tester.longPress(find.text('Played'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(en.actionsRemoveFromHistory));
    await tester.pumpAndSettle();
    expect(find.text(en.libraryEmptyHistory), findsOneWidget);
  });
}
