import '../api/models.dart';

class HistoryEntry {
  const HistoryEntry({required this.post, required this.playedAt});
  final PostRef post;
  final int playedAt; // epoch ms
}

class RatedPost {
  const RatedPost({required this.post, required this.rating});
  final PostRef post;
  final int rating; // 1–5
}

enum HistoryGroup { today, yesterday, week, older }

typedef HistorySection = ({HistoryGroup group, List<HistoryEntry> items});

DateTime _startOfDay(DateTime t) => DateTime(t.year, t.month, t.day);

List<HistorySection> groupHistory(List<HistoryEntry> entries, DateTime now) {
  final today = _startOfDay(now);
  HistoryGroup groupOf(int playedAt) {
    // Rounded so a DST-length day still counts as one day.
    final days = (today.difference(_startOfDay(DateTime.fromMillisecondsSinceEpoch(playedAt))).inMinutes / 1440).round();
    if (days <= 0) return HistoryGroup.today;
    if (days == 1) return HistoryGroup.yesterday;
    return days < 7 ? HistoryGroup.week : HistoryGroup.older;
  }

  final buckets = <HistoryGroup, List<HistoryEntry>>{};
  for (final e in entries) {
    (buckets[groupOf(e.playedAt)] ??= []).add(e);
  }
  return [for (final g in HistoryGroup.values) if (buckets[g] case final items?) (group: g, items: items)];
}

/// Library rows keep only a few fields; cards need the rest filled with neutral values.
PostSummary refToSummary(PostRef ref) => PostSummary(
      id: ref.id,
      title: ref.title,
      date: '',
      cover: ref.cover,
      cv: ref.cv,
      rjCode: ref.rjCode,
      circle: ref.circle,
    );
