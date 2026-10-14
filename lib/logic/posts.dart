import '../api/models.dart';

List<PostSummary> uniqueById(Iterable<PostSummary> items) {
  final seen = <int>{};
  return [for (final item in items) if (seen.add(item.id)) item];
}
