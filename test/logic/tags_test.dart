import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nihonkoe/api/models.dart';
import 'package:nihonkoe/logic/tags.dart';

TagIndexItem item(String name, String slug, [int count = 1]) =>
    TagIndexItem.from(TagIndexEntry(slug: slug, name: name, count: count));

void main() {
  final items = [item('Binaural', 'binaural', 9), item('耳かき', '耳かき', 5), item('Ear Cleaning', 'ear-cleaning', 3)];
  final hour = tagIndexTtl.inMilliseconds;
  List<String> names(List<TagIndexItem> list) => [for (final e in list) e.name];

  test('filterTags returns every item for a blank filter', () {
    expect(filterTags(items, '  '), items);
  });

  test('filterTags matches name or slug case-insensitively and keeps order', () {
    expect(names(filterTags(items, 'EAR')), ['Ear Cleaning']);
    expect(names(filterTags(items, 'ear-c')), ['Ear Cleaning']);
    expect(names(filterTags(items, 'in')), ['Binaural', 'Ear Cleaning']);
  });

  test('filterTags matches Japanese substrings and caps at the limit', () {
    expect(names(filterTags(items, '耳')), ['耳かき']);
    expect(filterTags(items, '', limit: 2).length, 2);
  });

  test('buildTagIndex dedupes by slug and sorts by count', () {
    final built = buildTagIndex(const [
      TagIndexEntry(slug: 'a', name: 'A', count: 1),
      TagIndexEntry(slug: 'b', name: 'B', count: 5),
      TagIndexEntry(slug: 'a', name: 'A again', count: 9),
    ]);
    expect(names(built), ['B', 'A']);
    expect(built.last.key, 'a\na');
  });

  test('parseTagCache returns items from a fresh entry', () {
    final raw = encodeTagCache(1000, items);
    final parsed = parseTagCache(raw, 1000 + hour - 1)!;
    expect(parsed.at, 1000);
    expect(names(parsed.items), names(items));
  });

  test('parseTagCache rejects missing, expired, future, corrupt and wrong-shape entries', () {
    expect(parseTagCache(null, 0), isNull);
    expect(parseTagCache(encodeTagCache(0, items), hour), isNull);
    expect(parseTagCache(encodeTagCache(5000, items), 1000), isNull);
    expect(parseTagCache('{not json', 0), isNull);
    expect(parseTagCache(jsonEncode({'at': 0, 'items': 'nope'}), 0), isNull);
    expect(parseTagCache(jsonEncode([1, 2]), 0), isNull);
    expect(parseTagCache(jsonEncode({'at': 0, 'items': [{}]}), 0), isNull);
  });

  test('parseTagCache treats an empty index as a miss so a bad fetch is not kept for 24h', () {
    expect(parseTagCache(encodeTagCache(0, const []), 0), isNull);
  });

  test('makeTagNamer maps known tag slugs, skipping voice actors and unknown slugs', () {
    final tags = [item('Binaural', 'binaural'), item('Ear Licking', 'ear-licking'), item('China Mugisawa', 'china-mugisawa')];
    final cvs = [item('China Mugisawa', 'china-mugisawa')];
    final name = makeTagNamer(tags, cvs);
    expect(name(['binaural', 'unknown', 'china-mugisawa', 'ear-licking'], 5), ['Binaural', 'Ear Licking']);
    expect(name(['binaural', 'ear-licking'], 1), ['Binaural']);
    expect(name(['binaural'], 0), isEmpty);
  });

  test('makeTagNamer returns nothing until the tag index is loaded', () {
    expect(makeTagNamer(null, null)(['binaural'], 2), isEmpty);
  });
}
