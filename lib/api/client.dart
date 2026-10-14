import 'models.dart';

String listUrl(ListQuery query, {int page = 1, ListSort sort = ListSort.newest}) {
  final p = page > 1 ? 'page/$page/' : '';
  final params = [
    if (query.kind == ListKind.search) 's=${Uri.encodeComponent(query.value)}',
    if (sort.params.isNotEmpty) sort.params,
  ].join('&');
  final qs = params.isEmpty ? '' : '?$params';
  return switch (query.kind) {
    ListKind.latest || ListKind.search => '$baseUrl/$p$qs',
    ListKind.tag => '$baseUrl/tag/${Uri.encodeFull(query.value)}/$p$qs',
    ListKind.category => '$baseUrl/category/${Uri.encodeFull(query.value)}/$p$qs',
  };
}

/// /tags/ and /cv/ list every tag (CVs are tags too).
String tagIndexUrl(TagIndex index) => '$baseUrl/${index.name}/';
