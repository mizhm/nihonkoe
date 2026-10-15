import 'package:flutter_test/flutter_test.dart';
import 'package:nihonkoe/api/client.dart';
import 'package:nihonkoe/api/models.dart';

void main() {
  test('listUrl', () {
    expect(listUrl(const ListQuery.search('ear lick'), page: 2), 'https://japaneseasmr.com/search/ear%20lick/page/2/');
    expect(listUrl(const ListQuery.tag('ear-licking')), 'https://japaneseasmr.com/tag/ear-licking/');
  });

  test('listUrl percent-encodes non-ASCII slugs and keeps slashes', () {
    expect(listUrl(const ListQuery.category('うこん')), 'https://japaneseasmr.com/category/%E3%81%86%E3%81%93%E3%82%93/');
    expect(listUrl(const ListQuery.category('rating/maniax'), page: 2), 'https://japaneseasmr.com/category/rating/maniax/page/2/');
  });

  test('listUrl sort params', () {
    expect(listUrl(const ListQuery.latest()), 'https://japaneseasmr.com/');
    expect(listUrl(const ListQuery.latest(), sort: ListSort.oldest), 'https://japaneseasmr.com/?orderby=date&order=asc');
    expect(listUrl(const ListQuery.tag('binaural'), page: 2, sort: ListSort.title), 'https://japaneseasmr.com/tag/binaural/page/2/?orderby=title&order=asc');
    expect(listUrl(const ListQuery.category('requested'), sort: ListSort.popularWeek), 'https://japaneseasmr.com/category/requested/?orderby=post_views&order=desc&date=week');
    expect(listUrl(const ListQuery.search('ear lick'), page: 2, sort: ListSort.popularAll), 'https://japaneseasmr.com/search/ear%20lick/page/2/?orderby=post_views&order=desc');
    expect(listUrl(const ListQuery.search('x'), sort: ListSort.popularYear), 'https://japaneseasmr.com/search/x/?orderby=post_views&order=desc&date=year');
  });

  test('tagIndexUrl', () {
    expect(tagIndexUrl(TagIndex.tags), 'https://japaneseasmr.com/tags/');
    expect(tagIndexUrl(TagIndex.cv), 'https://japaneseasmr.com/cv/');
  });

  test('toListSort falls back to newest for unknown persisted values', () {
    expect(toListSort('popular-month'), ListSort.popularMonth);
    expect(toListSort('comments'), ListSort.newest);
    expect(toListSort(null), ListSort.newest);
  });

  test('ListQuery has value equality', () {
    expect(const ListQuery.tag('a'), equals(const ListQuery.tag('a')));
    expect(const ListQuery.tag('a') == const ListQuery.category('a'), isFalse);
    expect(const ListQuery.search('x').hashCode, const ListQuery.search('x').hashCode);
  });
}
