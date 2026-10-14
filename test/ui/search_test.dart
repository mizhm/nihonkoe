import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:nihonkoe/api/client.dart';
import 'package:nihonkoe/api/models.dart';
import 'package:nihonkoe/app.dart';
import 'package:nihonkoe/data/db.dart';
import 'package:nihonkoe/logic/tags.dart';
import 'package:nihonkoe/state/search_history.dart';

import '../helpers.dart';

class FakeHistory implements SearchHistoryRepo {
  final items = <String>[];
  @override
  Future<List<String>> list() async => List.of(items);
  @override
  Future<void> push(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    items
      ..removeWhere((i) => i.toLowerCase() == q.toLowerCase())
      ..insert(0, q);
  }
  @override
  Future<void> remove(String query) async => items.remove(query);
  @override
  Future<void> clear() async => items.clear();
}

Future<void> openSearch(WidgetTester tester, List<Override> overrides) async {
  await tester.pumpWidget(ProviderScope(overrides: overrides, retry: noRetry, child: const NihonkoeApp()));
  await tester.pumpAndSettle();
  await tester.tap(find.text(en.tabsSearch));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('submitting a keyword stores it and opens results', (tester) async {
    final history = FakeHistory();
    final http = mockHttp({listUrl(const ListQuery.search('ear')): listHtml([5])});
    await openSearch(tester, [...await testOverrides(client: http), searchHistoryRepoProvider.overrideWithValue(history)]);
    expect(find.text(en.searchHint), findsOneWidget);
    await tester.enterText(find.byType(SearchBar), ' ear ');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(history.items, ['ear']);
    expect(find.text('Post 5'), findsOneWidget);
  });

  testWidgets('recent searches can be removed', (tester) async {
    final history = FakeHistory()..items.addAll(['binaural', 'ear']);
    await openSearch(tester, [...await testOverrides(), searchHistoryRepoProvider.overrideWithValue(history)]);
    expect(find.text('binaural'), findsOneWidget);
    await tester.tap(find.byTooltip(en.searchRemoveHistory('binaural')));
    await tester.pumpAndSettle();
    expect(find.text('binaural'), findsNothing);
    expect(history.items, ['ear']);
  });

  testWidgets('tags mode filters the tag index', (tester) async {
    TagIndexItem item(String name, String slug, int count) => TagIndexItem.from(TagIndexEntry(slug: slug, name: name, count: count));
    await openSearch(tester, [
      ...await testOverrides(tagIndex: [item('Binaural', 'binaural', 9), item('Ear Licking', 'ear-licking', 3)]),
      searchHistoryRepoProvider.overrideWithValue(FakeHistory()),
    ]);
    await tester.tap(find.text(en.searchModeTags));
    await tester.pumpAndSettle();
    expect(find.text('Binaural'), findsOneWidget);
    await tester.enterText(find.byType(SearchBar), 'lick');
    await tester.pumpAndSettle();
    expect(find.text('Binaural'), findsNothing);
    expect(find.text('Ear Licking'), findsOneWidget);
    expect(find.text(en.searchWorks(3)), findsOneWidget);
  });
}
