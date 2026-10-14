import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihonkoe/api/client.dart';
import 'package:nihonkoe/api/models.dart';
import 'package:nihonkoe/app.dart';
import 'package:nihonkoe/router.dart';
import 'package:nihonkoe/ui/links.dart';
import 'package:nihonkoe/ui/screens/home.dart';
import 'package:nihonkoe/ui/screens/results.dart';

import '../helpers.dart';

void main() {
  testWidgets('results layout toggle is labelled', (tester) async {
    await pumpRouted(tester, const ResultsScreen(query: ListQuery.tag('asmr'), title: 'ASMR'), overrides: await testOverrides());
    await tester.pumpAndSettle();
    expect(find.byTooltip(en.layoutSwitch(en.layoutCompact)), findsOneWidget);
  });

  testWidgets('search clear button is labelled', (tester) async {
    await tester.pumpWidget(ProviderScope(overrides: await testOverrides(), retry: noRetry, child: const NihonkoeApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.text(en.tabsSearch));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(SearchBar), 'ear');
    await tester.pumpAndSettle();
    expect(find.byTooltip(const DefaultMaterialLocalizations().clearButtonTooltip), findsOneWidget);
  });

  testWidgets('featured items without a loaded title still have a label', (tester) async {
    final handle = tester.ensureSemantics();
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final home = File('test/fixtures/home.html').readAsStringSync();
    await pumpRouted(tester, const HomeScreen(),
        overrides: await testOverrides(client: mockHttp({listUrl(const ListQuery.latest()): home})));
    await tester.pumpAndSettle();
    // The section header plus at least one carousel item.
    expect(find.bySemanticsLabel(en.homeFeatured), findsAtLeastNWidgets(2));
    handle.dispose();
  });

  testWidgets('the post cover is a labelled button that opens the gallery', (tester) async {
    final handle = tester.ensureSemantics();
    final html = File('test/fixtures/post.html').readAsStringSync();
    await tester.pumpWidget(ProviderScope(
      overrides: await testOverrides(client: mockHttp({'https://japaneseasmr.com/150207/': html})),
      retry: noRetry,
      child: const NihonkoeApp(),
    ));
    await tester.pumpAndSettle();
    containerOf(tester).read(routerProvider).push(postPath('', 150207));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel(en.detailOpenImage(1)).first);
    await tester.pumpAndSettle();
    expect(find.text('1 / 4'), findsOneWidget);
    handle.dispose();
  });
}
