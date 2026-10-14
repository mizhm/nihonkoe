const baseUrl = 'https://japaneseasmr.com';

/// Images (pic*.weeabo0.xyz) and audio (v.weeab0o.xyz) return 403 without this header.
const mediaHeaders = {'Referer': '$baseUrl/'};

class Term {
  const Term({required this.name, required this.slug});
  final String name;
  final String slug;

  @override
  bool operator ==(Object other) => other is Term && other.name == name && other.slug == slug;
  @override
  int get hashCode => Object.hash(name, slug);
  @override
  String toString() => 'Term($name, $slug)';
}

class Track {
  const Track({required this.title, required this.startSeconds});
  final String title;
  final int startSeconds;

  @override
  bool operator ==(Object other) => other is Track && other.title == title && other.startSeconds == startSeconds;
  @override
  int get hashCode => Object.hash(title, startSeconds);
  @override
  String toString() => 'Track($title, $startSeconds)';
}

class PostSummary {
  const PostSummary({
    required this.id,
    required this.title,
    required this.date,
    this.rjCode,
    this.cv,
    this.cover,
    this.categories = const [],
    this.circle,
    this.nsfw = false,
    this.tagSlugs = const [],
  });
  final int id;
  final String title;
  final String date; // YYYY-MM-DD
  final String? rjCode;
  final String? cv;
  final String? cover;
  final List<Term> categories;
  final String? circle; // the category that isn't a rating, "requested" or a genre
  final bool nsfw;
  final List<String> tagSlugs; // from the <li> classes; numeric ids of non-Latin tags are dropped
}

class PostDetail {
  const PostDetail({
    required this.id,
    required this.title,
    this.fullTitle,
    this.circle,
    this.rjCode,
    this.cv,
    this.cover,
    this.images = const [],
    this.streams = const [],
    this.tracks = const [],
    this.tags = const [],
    this.downloadUrl,
  });
  final int id;
  final String title;
  final String? fullTitle; // "[YYMMDD][circle] title [RJ…]"
  final String? circle;
  final String? rjCode;
  final String? cv;
  final String? cover;
  final List<String> images;
  final List<String> streams; // any audio format; play with mediaHeaders
  final List<Track> tracks;
  final List<Term> tags;
  final String? downloadUrl;

  String get url => '$baseUrl/$id/';
}

/// The slice of a post that lists, the library and the long-press sheet need.
class PostRef {
  const PostRef({required this.id, required this.title, this.cover, this.cv, this.rjCode, this.circle});
  factory PostRef.fromSummary(PostSummary p) =>
      PostRef(id: p.id, title: p.title, cover: p.cover, cv: p.cv, rjCode: p.rjCode, circle: p.circle);
  factory PostRef.fromDetail(PostDetail p) =>
      PostRef(id: p.id, title: p.title, cover: p.cover, cv: p.cv, rjCode: p.rjCode, circle: p.circle);
  final int id;
  final String title;
  final String? cover;
  final String? cv;
  final String? rjCode;
  final String? circle;

  String get url => '$baseUrl/$id/';
}

class FeaturedPost {
  const FeaturedPost({required this.id, this.cover});
  final int id;
  final String? cover;

  @override
  bool operator ==(Object other) => other is FeaturedPost && other.id == id && other.cover == cover;
  @override
  int get hashCode => Object.hash(id, cover);
  @override
  String toString() => 'FeaturedPost($id, $cover)';
}

class PostPage {
  const PostPage({required this.items, required this.page, required this.hasNext, this.featured = const []});
  final List<PostSummary> items;
  final int page;
  final bool hasNext;
  final List<FeaturedPost> featured; // the site-wide "Featured Posts" widget on the same page
}

class TagIndexEntry {
  const TagIndexEntry({required this.slug, required this.name, required this.count});
  final String slug;
  final String name;
  final int count;

  @override
  bool operator ==(Object other) =>
      other is TagIndexEntry && other.slug == slug && other.name == name && other.count == count;
  @override
  int get hashCode => Object.hash(slug, name, count);
  @override
  String toString() => 'TagIndexEntry($slug, $name, $count)';
}

enum TagIndex { tags, cv }

enum ListKind { latest, search, tag, category }

class ListQuery {
  const ListQuery._(this.kind, this.value);
  const ListQuery.latest() : this._(ListKind.latest, '');
  const ListQuery.search(String q) : this._(ListKind.search, q);
  const ListQuery.tag(String slug) : this._(ListKind.tag, slug);
  const ListQuery.category(String slug) : this._(ListKind.category, slug);

  final ListKind kind;
  final String value; // search text or slug; empty for latest

  @override
  bool operator ==(Object other) => other is ListQuery && other.kind == kind && other.value == value;
  @override
  int get hashCode => Object.hash(kind, value);
  @override
  String toString() => 'ListQuery(${kind.name}, $value)';
}

enum ListSort {
  newest('newest', ''),
  oldest('oldest', 'orderby=date&order=asc'),
  title('title', 'orderby=title&order=asc'),
  popularWeek('popular-week', 'orderby=post_views&order=desc&date=week'),
  popularMonth('popular-month', 'orderby=post_views&order=desc&date=month'),
  popularYear('popular-year', 'orderby=post_views&order=desc&date=year'),
  popularAll('popular-all', 'orderby=post_views&order=desc');

  const ListSort(this.id, this.params);
  final String id; // persisted value, same as the Expo app
  final String params;
}

ListSort toListSort(String? id) => ListSort.values.firstWhere((s) => s.id == id, orElse: () => ListSort.newest);
