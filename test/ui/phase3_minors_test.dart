import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nihonkoe/api/models.dart';
import 'package:nihonkoe/app.dart';
import 'package:nihonkoe/lock/authenticator.dart';
import 'package:nihonkoe/router.dart';
import 'package:nihonkoe/state/library.dart';
import 'package:nihonkoe/ui/links.dart';
import 'package:nihonkoe/ui/screens/post.dart';

import '../helpers.dart';
import '../player_fakes.dart';

class BrokenFavorites extends MemoryFavorites {
  BrokenFavorites({this.failList = false});
  final bool failList;
  @override
  Future<List<PostRef>> list() => failList ? Future.error(StateError('disk I/O error')) : super.list();
  @override
  Future<bool> toggle(PostRef post) => Future.error(StateError('disk I/O error'));
}

Future<void> app(WidgetTester tester, List<Override> overrides) async {
  tester.view.physicalSize = const Size(1080, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(overrides: overrides, retry: noRetry, child: const NihonkoeApp()));
  await tester.pumpAndSettle();
}

Future<void> openTab(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

final postHtml = File('test/fixtures/post.html').readAsStringSync();

void main() {
  testWidgets('back while locked does not pop the screens hidden under the cover', (tester) async {
    await app(tester, await testOverrides(prefs: {'language': 'en', 'appLock': true}, authenticator: FakeAuthenticator(results: [AuthResult.failed])));
    containerOf(tester).read(routerProvider).push(postPath('', 1));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(PostScreen, skipOffstage: false), findsOneWidget);
  });

  testWidgets('history times follow the 24-hour setting', (tester) async {
    tester.platformDispatcher.alwaysUse24HourFormatTestValue = true;
    addTearDown(tester.platformDispatcher.clearAlwaysUse24HourTestValue);
    final history = MemoryHistory();
    await history.recordPlay(const PostRef(id: 1, title: 'a'));
    final played = DateTime.fromMillisecondsSinceEpoch((await history.list()).single.playedAt);
    await app(tester, await testOverrides(history: history, handler: makeHandler(history: history)));
    await openTab(tester, en.tabsLibrary);
    await openTab(tester, en.libraryHistory);
    final hhmm = '${played.hour.toString().padLeft(2, '0')}:${played.minute.toString().padLeft(2, '0')}';
    expect(find.textContaining(hhmm), findsOneWidget);
  });

  testWidgets('day labels come from the shared clock (they move at midnight)', (tester) async {
    final history = MemoryHistory();
    await history.recordPlay(const PostRef(id: 1, title: 'a'));
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    await app(tester, [
      ...await testOverrides(history: history, handler: makeHandler(history: history)),
      clockProvider.overrideWithValue(() => tomorrow),
    ]);
    await openTab(tester, en.tabsLibrary);
    await openTab(tester, en.libraryHistory);
    expect(find.text(en.libraryGroupYesterday), findsOneWidget);
  });

  testWidgets('a library that cannot be read says so, with retry, instead of looking empty', (tester) async {
    await app(tester, await testOverrides(favorites: BrokenFavorites(failList: true)));
    await openTab(tester, en.tabsLibrary);
    expect(find.text(en.libraryEmptyFavorites), findsNothing);
    expect(find.text(en.listErrorTitle), findsOneWidget);
    expect(find.text(en.commonRetry), findsOneWidget);
  });

  testWidgets('a favorite that fails to save reports the error', (tester) async {
    await app(tester, await testOverrides(favorites: BrokenFavorites(), client: mockHttp({'https://japaneseasmr.com/150207/': postHtml})));
    containerOf(tester).read(routerProvider).push(postPath('', 150207));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(en.detailFavorite));
    await tester.pumpAndSettle();
    expect(find.text(en.listErrorTitle), findsOneWidget);
  });

  testWidgets('rated works read their stars as words', (tester) async {
    final ratings = MemoryRatings();
    await ratings.set(const PostRef(id: 1, title: 'Best'), 5);
    await app(tester, await testOverrides(ratings: ratings));
    await openTab(tester, en.tabsLibrary);
    await openTab(tester, en.libraryRated);
    expect(find.textContaining(en.libraryStars(5)), findsOneWidget);
    expect(find.textContaining('5★'), findsNothing);
  });

  testWidgets('privacy mode leaves gallery images sharp', (tester) async {
    await app(tester, await testOverrides(prefs: {'language': 'en', 'privacy': true}, client: mockHttp({'https://japaneseasmr.com/150207/': postHtml})));
    containerOf(tester).read(routerProvider).push(postPath('', 150207));
    await tester.pumpAndSettle();
    containerOf(tester).read(routerProvider).push(galleryPath(150207, 0));
    await tester.pumpAndSettle();
    expect(find.byType(ImageFiltered), findsNothing);
  });
}
