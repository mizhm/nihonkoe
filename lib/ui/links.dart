import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../api/models.dart';

const _branchRoots = {'search', 'library', 'settings'};

/// The current tab's root ('' for home), so shared routes open inside the tab the user is in.
String branchBase(BuildContext context) {
  final first = GoRouterState.of(context).matchedLocation.split('/').firstWhere((s) => s.isNotEmpty, orElse: () => '');
  return _branchRoots.contains(first) ? '/$first' : '';
}

String postPath(String base, int id) => '$base/post/$id';

String tagPath(String base, String slug, String name) =>
    '$base/tag/${Uri.encodeComponent(slug)}?name=${Uri.encodeQueryComponent(name)}';

String resultsPath(String base, ListQuery query, {ListSort sort = ListSort.newest, String? title}) {
  final params = {
    'kind': query.kind.name,
    if (query.value.isNotEmpty) 'value': query.value,
    'sort': sort.id,
    'title': ?title,
  };
  return '$base/results?${params.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&')}';
}

String galleryPath(int id, int index) => '/gallery/$id?index=$index';

ListQuery queryFromParams(Map<String, String> params) => switch (params['kind']) {
      'search' => ListQuery.search(params['value'] ?? ''),
      'tag' => ListQuery.tag(params['value'] ?? ''),
      'category' => ListQuery.category(params['value'] ?? ''),
      _ => const ListQuery.latest(),
    };
