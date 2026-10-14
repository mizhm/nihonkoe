import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihonkoe/api/client.dart';
import 'package:nihonkoe/api/models.dart';
import 'package:nihonkoe/app.dart';
import 'package:nihonkoe/router.dart';
import 'package:nihonkoe/ui/links.dart';

import '../helpers.dart';

void main() {
  testWidgets('a Japanese tag slug survives navigation and is requested once-encoded', (tester) async {
    final log = <String>[];
    final tagUrl = listUrl(const ListQuery.tag('耳かき'));
    expect(tagUrl, 'https://japaneseasmr.com/tag/%E8%80%B3%E3%81%8B%E3%81%8D/');
    await tester.pumpWidget(ProviderScope(
      overrides: await testOverrides(client: mockHttp({tagUrl: listHtml([7])}, log: log)),
      retry: noRetry,
      child: const NihonkoeApp(),
    ));
    await tester.pumpAndSettle();
    containerOf(tester).read(routerProvider).push(tagPath('', '耳かき', '耳かき'));
    await tester.pumpAndSettle();
    expect(log, contains(tagUrl));
    expect(find.text('Post 7'), findsOneWidget);
    expect(find.text('耳かき'), findsWidgets); // app bar title from ?name=
  });

  testWidgets('results honour the sort from the link and change it from the sort sheet', (tester) async {
    final log = <String>[];
    const q = ListQuery.search('ear');
    await tester.pumpWidget(ProviderScope(
      overrides: await testOverrides(client: mockHttp({
        listUrl(q, sort: ListSort.popularWeek): listHtml([1]),
        listUrl(q, sort: ListSort.oldest): listHtml([2]),
      }, log: log)),
      retry: noRetry,
      child: const NihonkoeApp(),
    ));
    await tester.pumpAndSettle();
    containerOf(tester).read(routerProvider).push(resultsPath('', q, sort: ListSort.popularWeek, title: 'ear'));
    await tester.pumpAndSettle();
    expect(find.text('Post 1'), findsOneWidget);
    // Home (below in the same tab) has a sort button too; the results one is the last.
    await tester.tap(find.byTooltip(en.sortHeading).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(en.sortOldest));
    await tester.pumpAndSettle();
    expect(find.text('Post 2'), findsOneWidget);
  });
}
