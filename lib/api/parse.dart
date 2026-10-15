import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

import 'models.dart';

// Site-wide categories that aren't circles: "requested" and genre sections (ratings are skipped by prefix).
const _nonCircleCategories = {'requested', 'otokonoko', 'futanari'};
const _nsfwRatings = {'rating/maniax', 'rating/extreme'};
final _rjCode = RegExp(r'\[((?:RJ|VJ|BJ)\d+)\]');
final _numeric = RegExp(r'^\d+$');

String? _safeDecode(String s) {
  try {
    return Uri.decodeComponent(s);
  } catch (_) {
    return null;
  }
}

String _trimSlash(String s) => s.endsWith('/') ? s.substring(0, s.length - 1) : s;

/// Links under `/<base>/` with an exact `rel`; a malformed slug is skipped rather than failing the page.
List<Term> _terms(Element scope, String rel, String base) {
  final prefix = '$baseUrl/$base/';
  final out = <Term>[];
  for (final a in scope.querySelectorAll('a')) {
    final href = a.attributes['href'];
    if (a.attributes['rel'] != rel || href == null || !href.startsWith(prefix)) continue;
    final slug = _safeDecode(_trimSlash(href.substring(prefix.length)));
    if (slug != null) out.add(Term(name: a.text.trim(), slug: slug));
  }
  return out;
}

String? _cv(Element scope) {
  for (final e in scope.querySelectorAll('*')) {
    final text = e.text.trim();
    if (e.children.isEmpty && text.startsWith('CV:')) return text.substring(3).trim();
  }
  return null;
}

List<FeaturedPost> _featured(Document doc) {
  final link = RegExp('^${RegExp.escape(baseUrl)}/(\\d+)/?\$');
  final seen = <int>{};
  final out = <FeaturedPost>[];
  for (final a in doc.querySelectorAll('#text-57 a[href]')) {
    final id = int.tryParse(link.firstMatch(a.attributes['href']!)?.group(1) ?? '');
    if (id != null && seen.add(id)) out.add(FeaturedPost(id: id, cover: a.querySelector('img')?.attributes['data-src']));
  }
  return out;
}

List<FeaturedPost> parseFeatured(String html) => _featured(html_parser.parse(html));

PostPage parseList(String html, int page) {
  final doc = html_parser.parse(html);
  final items = <PostSummary>[];
  for (final li in doc.querySelectorAll('li.site-archive-post')) {
    final idMatch = li.classes.map(RegExp(r'^post-(\d+)$').firstMatch).nonNulls.firstOrNull;
    if (idMatch == null) continue;
    final categories = _terms(li, 'category tag', 'category');
    final tagSlugs = <String>[];
    for (final c in li.classes) {
      if (!c.startsWith('tag-')) continue;
      final slug = _safeDecode(c.substring(4));
      if (slug != null && !_numeric.hasMatch(slug)) tagSlugs.add(slug);
    }
    items.add(PostSummary(
      id: int.parse(idMatch.group(1)!),
      title: li.querySelector('h2.entry-title a')?.text.trim() ?? '',
      date: li.querySelector('time[datetime]')?.attributes['datetime'] ?? '',
      rjCode: _rjCode.firstMatch(li.text)?.group(1),
      cv: _cv(li),
      cover: li.querySelector('[data-src]')?.attributes['data-src'],
      categories: categories,
      circle: categories
          .where((c) => !_nonCircleCategories.contains(c.slug) && !c.slug.startsWith('rating/'))
          .firstOrNull
          ?.name,
      nsfw: categories.any((c) => _nsfwRatings.contains(c.slug)),
      tagSlugs: tagSlugs,
    ));
  }
  return PostPage(
    items: items,
    page: page,
    hasNext: doc.querySelector('.next.page-numbers') != null,
    featured: _featured(doc),
  );
}

/// Every player tag's source, any format. The same track comes as several formats and repeats per
/// player, so keep the first url of each file name; some file names contain raw spaces.
List<String> _streams(Document doc) {
  final seen = <String>{};
  final out = <String>[];
  for (final e in doc.querySelectorAll('source, audio, video')) {
    final src = e.attributes['src'];
    if (src == null || src.isEmpty) continue;
    final url = src.replaceAll(' ', '%20');
    if (seen.add(url.replaceFirst(RegExp(r'\.\w+$'), ''))) out.add(url);
  }
  return out;
}

PostDetail parsePost(String html, int id) {
  final doc = html_parser.parse(html);
  final fullTitle = doc.querySelector('#work_title_jp')?.text.trim();
  final voice = doc.querySelector('#voice_actors')?.text.trim();
  // The tracklist is rendered once per player; read only the first table.
  final tracklist = doc.querySelector('table#plyr-chapter-playlist');
  return PostDetail(
    id: id,
    title: doc.querySelector('h1.page-title')?.text.trim() ?? '',
    fullTitle: fullTitle,
    circle: fullTitle == null ? null : RegExp(r'^\[\d+\]\[([^\]]+)\]').firstMatch(fullTitle)?.group(1),
    rjCode: RegExp(r"rjcode='([^']+)'").firstMatch(html)?.group(1) ??
        (fullTitle == null ? null : RegExp(r'\[((?:RJ|VJ|BJ)\d+)\]$').firstMatch(fullTitle)?.group(1)),
    // Older posts print the same "CV:" line without the id.
    cv: voice != null && voice.startsWith('CV:') ? voice.substring(3).trim() : _cv(doc.querySelector('.entry-content') ?? doc.documentElement!),
    cover: doc.querySelector('a#img_cover')?.attributes['href'],
    images: [for (final a in doc.querySelectorAll('a[id^="img_"]')) ?a.attributes['href']],
    streams: _streams(doc),
    tracks: tracklist == null
        ? const []
        : [
            for (final a in tracklist.querySelectorAll('a[data-track-title]'))
              Track(
                title: a.attributes['data-track-title']!.trim(),
                startSeconds: int.tryParse(a.attributes['data-value'] ?? '') ?? 0,
              ),
          ],
    tags: _terms(doc.documentElement!, 'tag', 'tag'),
    downloadUrl: doc
        .querySelectorAll('a[href]')
        .map((a) => a.attributes['href']!)
        .where((href) => href.startsWith('$baseUrl/dlc.php?f='))
        .firstOrNull,
  );
}

List<TagIndexEntry> parseTagIndex(String html) {
  final prefix = '$baseUrl/tag/';
  final count = RegExp(r'^\((\d+)\)$');
  final out = <TagIndexEntry>[];
  for (final a in html_parser.parse(html).querySelectorAll('a[title]')) {
    final href = a.attributes['href'] ?? '';
    final n = count.firstMatch(a.attributes['title']!);
    final label = a.querySelector('span.tag-groups-label');
    if (!href.startsWith(prefix) || n == null || label == null) continue;
    final slug = _safeDecode(_trimSlash(href.substring(prefix.length)));
    if (slug != null) out.add(TagIndexEntry(slug: slug, name: label.text.trim(), count: int.parse(n.group(1)!)));
  }
  return out;
}
