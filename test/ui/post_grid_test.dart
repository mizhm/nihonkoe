import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihonkoe/api/client.dart';
import 'package:nihonkoe/api/models.dart';
import 'package:nihonkoe/ui/widgets/post_grid.dart';
import 'package:nihonkoe/ui/widgets/post_row.dart';

import '../helpers.dart';

const key = (query: ListQuery.tag('asmr'), sort: ListSort.newest);

Widget grid() => const Scaffold(body: CustomScrollView(slivers: [PostSliverGrid(listKey: key)]));

void main() {
  testWidgets('renders posts and loads the next page when scrolled to the end', (tester) async {
    final log = <String>[];
    final http = mockHttp({
      listUrl(key.query): listHtml(List.generate(10, (i) => i + 1), next: true),
      listUrl(key.query, page: 2): listHtml([11, 12]),
    }, log: log);
    await pumpRouted(tester, grid(), overrides: await testOverrides(client: http));
    await tester.pumpAndSettle();
    expect(find.text('Post 1'), findsOneWidget);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -5000));
    await tester.pumpAndSettle();
    expect(log, contains(listUrl(key.query, page: 2)));
    expect(find.text('Post 12'), findsOneWidget);
  });

  testWidgets('a blocked site shows an error with retry', (tester) async {
    final http = mockHttp({listUrl(key.query): 'Just a moment...'}, status: 403);
    await pumpRouted(tester, grid(), overrides: await testOverrides(client: http));
    await tester.pumpAndSettle();
    expect(find.text(en.listErrorTitle), findsOneWidget);
    expect(find.text(en.commonRetry), findsOneWidget);
  });

  testWidgets('an empty list says so', (tester) async {
    await pumpRouted(tester, grid(), overrides: await testOverrides(client: mockHttp({listUrl(key.query): listHtml([])})));
    await tester.pumpAndSettle();
    expect(find.text(en.listEmpty), findsOneWidget);
  });

  testWidgets('long-press on a card opens the actions sheet', (tester) async {
    await pumpRouted(tester, grid(), overrides: await testOverrides(client: mockHttp({listUrl(key.query): listHtml([1])})));
    await tester.pumpAndSettle();
    await tester.longPress(find.text('Post 1'));
    await tester.pumpAndSettle();
    expect(find.text(en.actionsOpenWeb), findsOneWidget);
  });

  testWidgets('an empty row hides itself', (tester) async {
    await pumpRouted(
      tester,
      const Scaffold(body: PostRow(title: 'Hot', listKey: key, seeAllPath: '/results')),
      overrides: await testOverrides(client: mockHttp({listUrl(key.query): listHtml([])})),
    );
    await tester.pumpAndSettle();
    expect(find.text('Hot'), findsNothing);
  });
}
