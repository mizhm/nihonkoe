import 'package:flutter_test/flutter_test.dart';
import 'package:nihonkoe/api/models.dart';
import 'package:nihonkoe/logic/library.dart';

int at(int day, int hour, [int minute = 0]) => DateTime(2026, 10, day, hour, minute).millisecondsSinceEpoch;
HistoryEntry played(int id, int playedAt) => HistoryEntry(post: PostRef(id: id, title: 't$id'), playedAt: playedAt);

void main() {
  test('groupHistory buckets by local calendar day and keeps order', () {
    final now = DateTime(2026, 10, 13, 12);
    final groups = groupHistory([played(1, at(13, 0, 30)), played(2, at(12, 23, 30)), played(3, at(10, 9)), played(4, at(3, 9))], now);
    // Records compare a List field by identity, so compare a readable form.
    expect([for (final g in groups) '${g.group.name}:${[for (final e in g.items) e.post.id]}'], [
      'today:[1]',
      'yesterday:[2]',
      'week:[3]',
      'older:[4]',
    ]);
  });

  test('groupHistory omits empty groups and puts future stamps under today', () {
    final now = DateTime(2026, 10, 13, 12);
    expect([for (final g in groupHistory([played(1, at(13, 13)), played(2, at(1, 9))], now)) g.group], [HistoryGroup.today, HistoryGroup.older]);
    expect(groupHistory(const [], now), isEmpty);
  });

  test('groupHistory counts a DST-length day as one day', () {
    // 2026-10-25 is the EU DST switch; a 25-hour day must still be "yesterday".
    final now = DateTime(2026, 10, 26, 9);
    expect(groupHistory([played(1, DateTime(2026, 10, 25, 1).millisecondsSinceEpoch)], now).single.group, HistoryGroup.yesterday);
  });

  test('refToSummary fills list-only fields for cards', () {
    final s = refToSummary(const PostRef(id: 3, title: 't', cv: 'cv', rjCode: 'RJ1', circle: 'c'));
    expect((s.id, s.title, s.cv, s.rjCode, s.circle, s.date, s.categories, s.nsfw, s.tagSlugs), (3, 't', 'cv', 'RJ1', 'c', '', const <Term>[], false, const <String>[]));
  });
}
