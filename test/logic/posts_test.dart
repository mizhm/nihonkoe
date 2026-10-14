import 'package:flutter_test/flutter_test.dart';
import 'package:nihonkoe/api/models.dart';
import 'package:nihonkoe/logic/posts.dart';

void main() {
  test('uniqueById keeps the first occurrence in order', () {
    const a = PostSummary(id: 1, title: 'a', date: '');
    const b = PostSummary(id: 2, title: 'b', date: '');
    const c = PostSummary(id: 1, title: 'c', date: '');
    expect(uniqueById([a, b, c]).map((p) => p.title), ['a', 'b']);
  });
}
