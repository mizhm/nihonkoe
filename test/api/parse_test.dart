import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nihonkoe/api/models.dart';
import 'package:nihonkoe/api/parse.dart';

String fixture(String name) => File('test/fixtures/$name').readAsStringSync();

void main() {
  test('parseList: home page', () {
    final page = parseList(fixture('home.html'), 1);
    expect(page.items.length, 14);
    expect(page.hasNext, isTrue);
    final p = page.items.first;
    expect(p.id, 151348);
    expect(p.date, '2026-10-08');
    expect(p.rjCode, 'RJ01732047');
    expect(p.cv, 'China Mugisawa');
    expect(p.cover, 'https://pic.weeabo0.xyz/RJ01732047_img_main.jpg');
    expect(p.categories.map((c) => c.slug), ['rating/maniax', 'requested', 'うこんちゃん☆かんぱにぃ']);
    expect(p.title, startsWith('低音クールな猫耳執事'));
  });

  test('parseList: circle, nsfw and tag slugs', () {
    final items = parseList(fixture('home.html'), 1).items;
    final p = items.first;
    expect(p.circle, 'うこんちゃん☆かんぱにぃ');
    expect(p.nsfw, isTrue);
    expect(p.tagSlugs.take(2), ['beastkin', 'binaural']);
    expect(p.tagSlugs, contains('china-mugisawa'));
    expect(p.tagSlugs.any((s) => RegExp(r'^\d+$').hasMatch(s)), isFalse);
    final sfw = items.firstWhere((i) => i.categories.any((c) => c.slug == 'rating/sfw'));
    expect(sfw.nsfw, isFalse);
  });

  test('parseList: search page', () {
    expect(parseList(fixture('search.html'), 1).items, isNotEmpty);
  });

  test('parseList: no circle, bad encodings and look-alike classes', () {
    const html = '<ul><li class="site-archive-post post-7 post-tag-fake tag-%E0%A4%A tag-asmr tag-123">'
        '<a href="https://japaneseasmr.com/category/requested/" rel="category tag">Requested</a>'
        '<a href="https://japaneseasmr.com/category/rating/sfw/" rel="category tag">SFW</a>'
        '</li></ul>';
    final p = parseList(html, 1).items.single;
    expect(p.id, 7);
    expect(p.circle, isNull);
    expect(p.nsfw, isFalse);
    expect(p.tagSlugs, ['asmr']);
  });

  test('parseList: genre categories are not circles, extreme is nsfw', () {
    String cat(String slug, String name) => '<a href="https://japaneseasmr.com/category/$slug/" rel="category tag">$name</a>';
    final html = '<ul><li class="site-archive-post post-8">${cat('rating/extreme', 'Extreme')}${cat('otokonoko', 'Otoko no ko')}'
        '${cat('futanari', 'Futanari')}${cat('raro', 'RaRo')}</li></ul>';
    final p = parseList(html, 1).items.single;
    expect(p.circle, 'RaRo');
    expect(p.nsfw, isTrue);
  });

  test('parseList: a malformed category link is skipped instead of failing the page', () {
    const html = '<ul><li class="site-archive-post post-9">'
        '<a href="https://japaneseasmr.com/category/%E0%A4%A/" rel="category tag">Bad</a>'
        '<a href="https://japaneseasmr.com/category/raro/" rel="category tag">RaRo</a>'
        '</li></ul>';
    expect(parseList(html, 1).items.single.categories.map((c) => c.slug), ['raro']);
  });

  test('parseList: last page has no next link', () {
    expect(parseList('<ul><li class="site-archive-post post-1"></li></ul>', 3).hasNext, isFalse);
  });

  test('parsePost: detail page', () {
    final p = parsePost(fixture('post.html'), 150207);
    expect(p.rjCode, 'RJ01700554');
    expect(p.circle, 'HONEY NOIR');
    expect(p.cv, '木蜜甜花');
    expect(p.streams, ['https://v.weeab0o.xyz/RJ01700554.m3u8']);
    expect(p.tracks.length, 15);
    expect(p.tracks[1], const Track(title: '02_下から耳を舐め上げる_右', startSeconds: 607));
    expect(p.images.length, 4);
    expect(p.cover, 'https://pic.weeabo0.xyz/RJ01700554_img_main.jpg');
    expect(p.tags.any((t) => t.slug == 'ear-licking'), isTrue);
    expect(p.downloadUrl, 'https://japaneseasmr.com/dlc.php?f=RJ01700554');
  });

  test('parsePost: older post with mp3/m4a sources keeps one url per track', () {
    final p = parsePost(fixture('post_mp3.html'), 124598);
    expect(p.streams, ['https://v.weeab0o.xyz/RJ01264717.mp3']);
  });

  test('parsePost: any audio format, raw spaces encoded, one url per file name', () {
    const html = '<h1 class="page-title">t</h1>'
        '<video><source src="https://v.weeab0o.xyz/RJ1.mp3" type="audio/mpeg"/><source src="https://v.weeab0o.xyz/RJ1.m4a"/></video>'
        '<audio><source id="a_mp3" src="https://v.weeab0o.xyz/RJ1.mp3"></audio>'
        '<audio src="https://v.weeab0o.xyz/RJ1 BGM.ogg"></audio>';
    expect(parsePost(html, 1).streams, ['https://v.weeab0o.xyz/RJ1.mp3', 'https://v.weeab0o.xyz/RJ1%20BGM.ogg']);
  });

  test('parsePost: an older post has its CV line without the voice_actors id', () {
    const html = '<div class="entry-content"><p style="text-align: center;">CV: Ryou Suzuki, Chiroru Oyama</p>'
        '<p>裕子(CV:秋山はるる)</p></div>';
    expect(parsePost(html, 1).cv, 'Ryou Suzuki, Chiroru Oyama');
  });

  test('parsePost: a post without audio has no streams', () {
    final p = parsePost('<h1 class="page-title">Only text</h1>', 2);
    expect(p.title, 'Only text');
    expect(p.streams, isEmpty);
    expect(p.tracks, isEmpty);
  });

  test('parseTagIndex: tag-groups entries with slug, label and count', () {
    const html = '<span class="tag-groups-tag"><a href="https://japaneseasmr.com/tag/dirty-talk/" title="(3902)" class="dirty-talk">'
        '<span class="tag-groups-label">Dirty Talk 【淫語】</span></a></span>'
        '<span class="tag-groups-tag"><a href="https://japaneseasmr.com/tag/%e6%9c%a8%e8%9c%9c%e7%94%9c%e8%8a%b1/" title="(1)" class="x">'
        '<span class="tag-groups-label">Kimitsu Tenka &amp; co</span></a></span>';
    expect(parseTagIndex(html), const [
      TagIndexEntry(slug: 'dirty-talk', name: 'Dirty Talk 【淫語】', count: 3902),
      TagIndexEntry(slug: '木蜜甜花', name: 'Kimitsu Tenka & co', count: 1),
    ]);
  });

  test('parseFeatured: reads the Featured Posts widget', () {
    final featured = parseFeatured(fixture('home.html'));
    expect(featured.length, 8);
    expect(featured.first, const FeaturedPost(id: 138259, cover: 'https://pic.weeabo0.xyz/RJ01473335_img_main.jpg'));
    expect(parseList(fixture('home.html'), 1).featured, featured);
  });

  test('parseFeatured: missing widget gives an empty list', () {
    expect(parseFeatured('<div id="text-99"><a href="https://japaneseasmr.com/1/"><img data-src="x"></a></div>'), isEmpty);
  });
}
