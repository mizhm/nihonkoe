import 'package:flutter_test/flutter_test.dart';
import 'package:nihonkoe/api/models.dart';
import 'package:nihonkoe/ui/links.dart';

void main() {
  test('paths stay inside the current branch', () {
    expect(postPath('', 5), '/post/5');
    expect(postPath('/search', 5), '/search/post/5');
  });

  test('tagPath encodes non-ASCII slugs and names', () {
    expect(tagPath('', '耳かき', 'Ear & co'), '/tag/%E8%80%B3%E3%81%8B%E3%81%8D?name=Ear+%26+co');
  });

  test('results params round-trip', () {
    final path = resultsPath('/search', const ListQuery.category('requested'), sort: ListSort.popularWeek, title: 'Hot');
    final uri = Uri.parse(path);
    expect(uri.path, '/search/results');
    expect(queryFromParams(uri.queryParameters), const ListQuery.category('requested'));
    expect(uri.queryParameters['sort'], 'popular-week');
    expect(uri.queryParameters['title'], 'Hot');
    expect(queryFromParams({}), const ListQuery.latest());
  });

  test('galleryPath', () => expect(galleryPath(9, 2), '/gallery/9?index=2'));
}
