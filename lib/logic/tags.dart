import 'dart:convert';

import '../api/models.dart';

const tagIndexTtl = Duration(hours: 24);

/// Precomputed once so filtering doesn't lowercase every entry per keystroke.
String tagKey(String name, String slug) => '$name\n$slug'.toLowerCase();

class TagIndexItem {
  const TagIndexItem({required this.slug, required this.name, required this.count, required this.key});
  TagIndexItem.from(TagIndexEntry e) : this(slug: e.slug, name: e.name, count: e.count, key: tagKey(e.name, e.slug));

  final String slug;
  final String name;
  final int count;
  final String key;

  Map<String, Object> toJson() => {'slug': slug, 'name': name, 'count': count, 'key': key};

  static TagIndexItem? fromJson(Object? json) {
    if (json case {'slug': String slug, 'name': String name, 'count': int count, 'key': String key}) {
      return TagIndexItem(slug: slug, name: name, count: count, key: key);
    }
    return null;
  }
}

List<TagIndexItem> filterTags(List<TagIndexItem> items, String filter, {int? limit}) {
  final needle = filter.trim().toLowerCase();
  final matches = needle.isEmpty ? items : items.where((item) => item.key.contains(needle)).toList();
  return limit == null || matches.length <= limit ? matches : matches.sublist(0, limit);
}

List<TagIndexItem> buildTagIndex(List<TagIndexEntry> entries) {
  final seen = <String>{};
  final unique = [for (final e in entries) if (seen.add(e.slug)) e]..sort((a, b) => b.count.compareTo(a.count));
  return [for (final e in unique) TagIndexItem.from(e)];
}

String encodeTagCache(int at, List<TagIndexItem> items) =>
    jsonEncode({'at': at, 'items': [for (final i in items) i.toJson()]});

({int at, List<TagIndexItem> items})? parseTagCache(String? raw, int now) {
  if (raw == null) return null;
  final Object? json;
  try {
    json = jsonDecode(raw);
  } on FormatException {
    return null;
  }
  if (json case {'at': int at, 'items': List<Object?> rawItems}) {
    // A future timestamp means the clock moved; don't trust that entry.
    if (at > now || now - at >= tagIndexTtl.inMilliseconds) return null;
    final items = [for (final i in rawItems) TagIndexItem.fromJson(i)];
    // An empty or old-shape index (bad fetch, changed format) is a miss, never a 24h dead end.
    if (items.isEmpty || items.any((i) => i == null)) return null;
    return (at: at, items: items.cast<TagIndexItem>());
  }
  return null;
}

typedef TagNamer = List<String> Function(List<String> slugs, int limit);

/// Built once per index change; cards call the returned function per post.
TagNamer makeTagNamer(List<TagIndexItem>? tags, List<TagIndexItem>? cvs) {
  final names = {for (final t in tags ?? const <TagIndexItem>[]) t.slug: t.name};
  final voices = {for (final c in cvs ?? const <TagIndexItem>[]) c.slug}; // CVs already have their own label
  return (slugs, limit) {
    final out = <String>[];
    for (final slug in slugs) {
      if (out.length >= limit) break;
      final name = names[slug];
      if (name != null && !voices.contains(slug)) out.add(name);
    }
    return out;
  };
}
