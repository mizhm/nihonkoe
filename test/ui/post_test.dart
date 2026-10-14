import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihonkoe/app.dart';
import 'package:nihonkoe/router.dart';
import 'package:nihonkoe/ui/links.dart';
import 'package:nihonkoe/ui/screens/gallery.dart';

import '../helpers.dart';

Future<void> openPost(WidgetTester tester, Map<String, String> routes, {int id = 150207, int status = 200}) async {
  tester.view.physicalSize = const Size(1080, 6000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: await testOverrides(client: mockHttp(routes, status: status)),
    retry: noRetry,
    child: const NihonkoeApp(),
  ));
  await tester.pumpAndSettle();
  containerOf(tester).read(routerProvider).push(postPath('', id));
  await tester.pumpAndSettle();
}

void main() {
  final html = File('test/fixtures/post.html').readAsStringSync();

  testWidgets('shows title, people, chapters, tags; playback disabled for now', (tester) async {
    await openPost(tester, {'https://japaneseasmr.com/150207/': html});
    expect(find.text('HONEY NOIR'), findsOneWidget);
    expect(find.text('木蜜甜花'), findsNWidgets(2)); // CV chip + the same name in the tag list (CVs are tags)
    expect(find.text(en.detailChapters(15)), findsOneWidget);
    expect(find.text('02_下から耳を舐め上げる_右'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, 'Ear Licking 【耳舐め】'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, en.detailPlay)).onPressed, isNull);
  });

  testWidgets('a missing post says not found', (tester) async {
    await openPost(tester, {}, id: 1);
    expect(find.text(en.detailNotFound), findsOneWidget);
  });

  testWidgets('a blocked site shows the load error with retry', (tester) async {
    await openPost(tester, {'https://japaneseasmr.com/150207/': 'blocked'}, status: 403);
    expect(find.text(en.detailLoadFailed), findsOneWidget);
    expect(find.text(en.commonRetry), findsOneWidget);
  });

  testWidgets('tapping an image opens the gallery at that page', (tester) async {
    await openPost(tester, {'https://japaneseasmr.com/150207/': html});
    await tester.tap(find.byTooltip(en.detailOpenImage(2)));
    await tester.pumpAndSettle();
    expect(find.byType(GalleryScreen), findsOneWidget);
    expect(find.text('2 / 4'), findsOneWidget);
  });
}
