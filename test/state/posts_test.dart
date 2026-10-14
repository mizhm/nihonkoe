import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihonkoe/api/client.dart';
import 'package:nihonkoe/api/models.dart';
import 'package:nihonkoe/state/core.dart';
import 'package:nihonkoe/state/posts.dart';

import '../helpers.dart';

void main() {
  const key = (query: ListQuery.tag('asmr'), sort: ListSort.newest);
  final page1 = listUrl(key.query);
  final page2 = listUrl(key.query, page: 2);

  ProviderContainer containerFor(Map<String, String> routes, {List<String>? log, Directory? cache}) => ProviderContainer.test(
        overrides: [
          httpClientProvider.overrideWithValue(mockHttp(routes, log: log)),
          if (cache != null) cacheDirProvider.overrideWith((ref) async => cache),
        ],
        retry: (_, _) => null,
      );

  test('first page, then loadMore appends and removes duplicates', () async {
    final c = containerFor({page1: listHtml([1, 2], next: true), page2: listHtml([2, 3])});
    final sub = c.listen(postListProvider(key), (_, _) {});
    await c.read(postListProvider(key).future);
    await c.read(postListProvider(key).notifier).loadMore();
    final state = sub.read().value!;
    expect(state.posts.map((p) => p.id), [1, 2, 3]);
    expect(state.page, 2);
    expect(state.hasNext, isFalse);
  });

  test('concurrent loadMore calls fetch the next page once', () async {
    final log = <String>[];
    final c = containerFor({page1: listHtml([1], next: true), page2: listHtml([2], next: true)}, log: log);
    c.listen(postListProvider(key), (_, _) {});
    await c.read(postListProvider(key).future);
    final n = c.read(postListProvider(key).notifier);
    await Future.wait([n.loadMore(), n.loadMore(), n.loadMore()]);
    expect(log.where((u) => u == page2).length, 1);
  });

  test('a 404 next page ends the list and keeps loaded posts', () async {
    final c = containerFor({page1: listHtml([1], next: true)}); // page 2 → 404 → empty final page
    c.listen(postListProvider(key), (_, _) {});
    await c.read(postListProvider(key).future);
    await c.read(postListProvider(key).notifier).loadMore();
    final state = c.read(postListProvider(key)).value!;
    expect(state.posts.map((p) => p.id), [1]);
    expect(state.hasNext, isFalse);
  });

  test('first page error surfaces as AsyncError', () async {
    final c = ProviderContainer.test(
      overrides: [httpClientProvider.overrideWithValue(mockHttp({page1: 'blocked'}, status: 403))],
      retry: (_, _) => null,
    );
    c.listen(postListProvider(key), (_, _) {});
    await expectLater(c.read(postListProvider(key).future), throwsA(isA<ApiException>()));
  });

  test('featuredProvider reads the widget from the latest page', () async {
    final home = File('test/fixtures/home.html').readAsStringSync();
    final c = containerFor({listUrl(const ListQuery.latest()): home});
    c.listen(featuredProvider, (_, _) {});
    expect((await c.read(featuredProvider.future)).length, 8);
  });

  test('tagIndexProvider caches the parsed index on disk for the next launch', () async {
    final dir = await Directory.systemTemp.createTemp('tags');
    addTearDown(() => dir.delete(recursive: true));
    final log = <String>[];
    final routes = {
      tagIndexUrl(TagIndex.cv): '<a href="https://japaneseasmr.com/tag/a/" title="(2)"><span class="tag-groups-label">A</span></a>',
    };
    final first = containerFor(routes, log: log, cache: dir);
    expect((await first.read(tagIndexProvider(TagIndex.cv).future)).single.name, 'A');
    final second = containerFor(routes, log: log, cache: dir);
    expect((await second.read(tagIndexProvider(TagIndex.cv).future)).single.name, 'A');
    expect(log.length, 1);
  });
}
