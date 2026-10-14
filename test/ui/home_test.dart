import 'dart:convert';
import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nihonkoe/state/core.dart';
import 'package:nihonkoe/state/posts.dart';
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

  testWidgets('home shows the featured carousel and one latest list, no extra rows', (tester) async {
    await tallScreen(tester);
    await pumpRouted(tester, const HomeScreen(), overrides: await testOverrides(client: mockHttp(routes(home))));
    await tester.pumpAndSettle();
    expect(find.text(en.homeFeatured), findsOneWidget);
    expect(find.text(en.homeLatest), findsOneWidget, reason: 'the feed picker names the current feed');
    expect(find.text(en.homeHotWeek), findsNothing);
    expect(find.text('Post 101'), findsNothing);
  });

  testWidgets('picking a feed swaps the list, hides featured and is remembered', (tester) async {
    await tallScreen(tester);
    await pumpRouted(tester, const HomeScreen(), overrides: await testOverrides(client: mockHttp(routes(home))));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(en.homeFeedPick));
    await tester.pumpAndSettle();
    await tester.tap(find.text(en.homeHotWeek).last);
    await tester.pumpAndSettle();
    expect(find.text('Post 101'), findsOneWidget);
    expect(find.text(en.homeFeatured), findsNothing);
    expect(containerOf(tester).read(prefsProvider).getString('homeFeed'), 'hotWeek');
  });

  testWidgets('the saved feed opens at launch', (tester) async {
    await tallScreen(tester);
    await pumpRouted(tester, const HomeScreen(),
        overrides: await testOverrides(client: mockHttp(routes(home)), prefs: {'language': 'en', 'homeFeed': 'requested'}));
    await tester.pumpAndSettle();
    expect(find.text('Post 301'), findsOneWidget);
    expect(find.text(en.feedRequested), findsOneWidget);
  });

  testWidgets('hot feeds have a fixed order, so sort explains instead of opening', (tester) async {
    await tallScreen(tester);
    await pumpRouted(tester, const HomeScreen(),
        overrides: await testOverrides(client: mockHttp(routes(home)), prefs: {'language': 'en', 'homeFeed': 'hotMonth'}));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(en.sortHeading));
    await tester.pumpAndSettle();
    expect(find.text(en.sortFixedHot), findsOneWidget);
    expect(find.text(en.sortNewest), findsNothing);
  });

  testWidgets('featured block disappears when the site widget is missing', (tester) async {
    await tallScreen(tester);
    final withoutWidget = home.replaceAll('id="text-57"', 'id="text-00"');
    await pumpRouted(tester, const HomeScreen(), overrides: await testOverrides(client: mockHttp(routes(withoutWidget))));
    await tester.pumpAndSettle();
    expect(find.text(en.homeFeatured), findsNothing);
    expect(find.text(en.homeLatest), findsOneWidget);
  });

  testWidgets('long-press on a featured item opens the actions sheet', (tester) async {
    await tallScreen(tester);
    await pumpRouted(tester, const HomeScreen(), overrides: await testOverrides(client: mockHttp(routes(home))));
    await tester.pumpAndSettle();
    await tester.longPress(find.byKey(const ValueKey('featured-138259')));
    await tester.pumpAndSettle();
    expect(find.text(en.actionsOpenWeb), findsOneWidget);
  });

  testWidgets('pull-to-refresh reloads home only and reports a failed refresh', (tester) async {
    await tallScreen(tester);
    final log = <String>[];
    var status = 200;
    final tagUrl = listUrl(const ListQuery.tag('asmr'));
    final served = {...routes(home), tagUrl: listHtml([77])};
    final client = MockClient((req) async {
      final url = req.url.toString();
      log.add(url);
      final body = served[url];
      return body == null ? http.Response('', 404) : http.Response.bytes(utf8.encode(body), status);
    });
    await pumpRouted(tester, const HomeScreen(), overrides: await testOverrides(client: client));
    await tester.pumpAndSettle();
    // A list another tab keeps open.
    containerOf(tester).listen(postListProvider((query: const ListQuery.tag('asmr'), sort: ListSort.newest)), (_, _) {});
    await tester.pumpAndSettle();
    expect(log.where((u) => u == tagUrl).length, 1);

    status = 403;
    final before = log.length;
    tester.state<RefreshIndicatorState>(find.byType(RefreshIndicator)).show();
    await tester.pumpAndSettle();
    expect(log.length, greaterThan(before), reason: 'the refresh ran');
    expect(log.where((u) => u == tagUrl).length, 1, reason: 'refreshing home must not reload other screens');
    expect(find.text(en.listRefreshFailed), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pull-to-refresh retries a tag index that failed at launch', (tester) async {
    await tallScreen(tester);
    var calls = 0;
    var siteUp = false;
    await pumpRouted(tester, const HomeScreen(),
        overrides: await testOverrides(
          client: mockHttp(routes(home)),
          loadTagIndex: (_) async {
            calls++;
            if (!siteUp) throw Exception('site down');
            return const [];
          },
        ));
    await tester.pumpAndSettle();
    final failedCalls = calls;
    siteUp = true;
    tester.state<RefreshIndicatorState>(find.byType(RefreshIndicator)).show();
    await tester.pumpAndSettle();
    expect(calls, greaterThan(failedCalls));
  });
}
