import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nihonkoe/api/models.dart';
import 'package:nihonkoe/app.dart';
import 'package:nihonkoe/router.dart';
import 'package:nihonkoe/ui/links.dart';
import 'package:nihonkoe/ui/sheets/post_actions.dart';

import '../helpers.dart';
import '../player_fakes.dart';

final postHtml = File('test/fixtures/post.html').readAsStringSync();

Future<(MemoryFavorites, MemoryRatings)> openPost(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 6000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final favorites = MemoryFavorites();
  final ratings = MemoryRatings();
  await tester.pumpWidget(ProviderScope(
    overrides: await testOverrides(
      client: mockHttp({'https://japaneseasmr.com/150207/': postHtml}),
      favorites: favorites,
      ratings: ratings,
    ),
    retry: noRetry,
    child: const NihonkoeApp(),
  ));
  await tester.pumpAndSettle();
  containerOf(tester).read(routerProvider).push(postPath('', 150207));
  await tester.pumpAndSettle();
  return (favorites, ratings);
}

void main() {
  testWidgets('favorite toggles from the post page', (tester) async {
    final (favorites, _) = await openPost(tester);
    await tester.tap(find.byTooltip(en.detailFavorite));
    await tester.pumpAndSettle();
    expect((await favorites.list()).single.id, 150207);
    expect(find.byTooltip(en.detailUnfavorite), findsOneWidget);
    await tester.tap(find.byTooltip(en.detailUnfavorite));
    await tester.pumpAndSettle();
    expect(await favorites.list(), isEmpty);
  });

  testWidgets('stars rate the work; tapping the same star clears it', (tester) async {
    final (_, ratings) = await openPost(tester);
    await tester.tap(find.byTooltip(en.detailRate(4)));
    await tester.pumpAndSettle();
    expect((await ratings.list()).single.rating, 4);
    await tester.tap(find.byTooltip(en.detailRate(4)));
    await tester.pumpAndSettle();
    expect(await ratings.list(), isEmpty);
  });

  testWidgets('long-press sheet toggles favorite and, in history, removes the entry', (tester) async {
    final favorites = MemoryFavorites();
    final history = MemoryHistory();
    await history.recordPlay(const PostRef(id: 1, title: 'T'));
    await pumpRouted(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: Column(children: [
            TextButton(onPressed: () => showPostActions(context, const PostRef(id: 1, title: 'T')), child: const Text('open')),
            TextButton(
              onPressed: () => showPostActions(context, const PostRef(id: 1, title: 'T'), inHistory: true),
              child: const Text('open history'),
            ),
          ]),
        ),
      ),
      overrides: await testOverrides(favorites: favorites, history: history),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text(en.actionsRemoveFromHistory), findsNothing);
    await tester.tap(find.text(en.detailFavorite));
    await tester.pumpAndSettle();
    expect((await favorites.list()).single.id, 1);
    await tester.tap(find.text('open history'));
    await tester.pumpAndSettle();
    expect(find.text(en.detailUnfavorite), findsOneWidget);
    await tester.tap(find.text(en.actionsRemoveFromHistory));
    await tester.pumpAndSettle();
    expect(await history.list(), isEmpty);
  });
}
