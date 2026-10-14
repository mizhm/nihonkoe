import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihonkoe/api/client.dart';
import 'package:nihonkoe/api/models.dart';
import 'package:nihonkoe/ui/screens/home.dart';

import '../helpers.dart';

Map<String, String> routes(String homeHtml) => {
      listUrl(const ListQuery.latest()): homeHtml,
      listUrl(const ListQuery.latest(), sort: ListSort.popularWeek): listHtml([101]),
      listUrl(const ListQuery.latest(), sort: ListSort.popularMonth): listHtml([201]),
      listUrl(const ListQuery.category('requested')): listHtml([301]),
    };

Future<void> tallScreen(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 8000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  final home = File('test/fixtures/home.html').readAsStringSync();

  testWidgets('sections appear in order: featured, hot week, hot month, requested, latest', (tester) async {
    await tallScreen(tester);
    await pumpRouted(tester, const HomeScreen(), overrides: await testOverrides(client: mockHttp(routes(home))));
    await tester.pumpAndSettle();
    final order = [en.homeFeatured, en.homeHotWeek, en.homeHotMonth, en.feedRequested, en.homeLatest]
        .map((t) => tester.getTopLeft(find.text(t).first).dy)
        .toList();
    expect(order, orderedEquals([...order]..sort()));
    expect(find.text('Post 101'), findsOneWidget);
  });

  testWidgets('featured block disappears when the site widget is missing', (tester) async {
    await tallScreen(tester);
    final withoutWidget = home.replaceAll('id="text-57"', 'id="text-00"');
    await pumpRouted(tester, const HomeScreen(), overrides: await testOverrides(client: mockHttp(routes(withoutWidget))));
    await tester.pumpAndSettle();
    expect(find.text(en.homeFeatured), findsNothing);
    expect(find.text(en.homeHotWeek), findsOneWidget);
  });

  testWidgets('long-press on a featured item opens the actions sheet', (tester) async {
    await tallScreen(tester);
    await pumpRouted(tester, const HomeScreen(), overrides: await testOverrides(client: mockHttp(routes(home))));
    await tester.pumpAndSettle();
    await tester.longPress(find.byKey(const ValueKey('featured-138259')));
    await tester.pumpAndSettle();
    expect(find.text(en.actionsOpenWeb), findsOneWidget);
  });
}
