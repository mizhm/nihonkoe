import 'dart:convert';
import 'dart:isolate';

import 'package:http/http.dart' as http;

import 'models.dart';
import 'parse.dart';

String listUrl(ListQuery query, {int page = 1, ListSort sort = ListSort.newest}) {
  final p = page > 1 ? 'page/$page/' : '';
  final params = [
    if (sort.params.isNotEmpty) sort.params,
  ].join('&');
  final qs = params.isEmpty ? '' : '?$params';
  return switch (query.kind) {
    ListKind.latest => '$baseUrl/$p$qs',
    // Path form: Cloudflare challenges every URL with a query string. A '/' in the text would 404.
    ListKind.search => '$baseUrl/search/${Uri.encodeComponent(query.value.replaceAll('/', ' '))}/$p$qs',
    ListKind.tag => '$baseUrl/tag/${Uri.encodeFull(query.value)}/$p$qs',
    ListKind.category => '$baseUrl/category/${Uri.encodeFull(query.value)}/$p$qs',
  };
}

/// /tags/ and /cv/ list every tag (CVs are tags too).
String tagIndexUrl(TagIndex index) => '$baseUrl/${index.name}/';

class ApiException implements Exception {
  const ApiException(this.url, this.statusCode);
  final String url;
  final int statusCode;

  @override
  String toString() => 'GET $url -> $statusCode';
}

/// Cloudflare wants a person to pass its check; solving it once in a visible WebView unblocks the app.
class ChallengeException extends ApiException {
  const ChallengeException(String url) : super(url, 403);
}

// The site has no JSON API (/wp-json is 401, /feed disabled), so this fetches server-rendered HTML.
const _pageHeaders = {'User-Agent': 'Mozilla/5.0 (Linux; Android 14; Mobile) nihonkoe'};

class ApiClient {
  ApiClient(this._http, {this.timeout = const Duration(seconds: 20), this.solveChallenge});
  final http.Client _http;

  /// Fetches a page through a real browser when Cloudflare answers with a JS challenge (sorted lists).
  final Future<String?> Function(String url)? solveChallenge;

  /// dart:io's HttpClient never gives up on a silent server; surface it as an error so retry and the error UI run.
  final Duration timeout;

  Future<String?> _getHtml(String url) async {
    final res = await _http.get(Uri.parse(url), headers: _pageHeaders).timeout(timeout);
    if (res.statusCode == 404) return null;
    if (res.statusCode == 403 && res.headers['cf-mitigated'] == 'challenge' && solveChallenge != null) return solveChallenge!(url);
    if (res.statusCode < 200 || res.statusCode >= 300) throw ApiException(url, res.statusCode);
    return utf8.decode(res.bodyBytes, allowMalformed: true);
  }

  Future<PostPage> listPosts(ListQuery query, {int page = 1, ListSort sort = ListSort.newest}) async {
    final html = await _getHtml(listUrl(query, page: page, sort: sort));
    // WordPress 404s past the last page (and for empty searches on page > 1).
    return html == null ? PostPage(items: const [], page: page, hasNext: false) : parseList(html, page);
  }

  Future<PostDetail?> getPost(int id) async {
    final html = await _getHtml('$baseUrl/$id/');
    return html == null ? null : parsePost(html, id);
  }

  /// The index pages are ~700 KB of HTML; parse off the UI isolate.
  Future<List<TagIndexEntry>> listTagIndex(TagIndex index) async {
    final html = await _getHtml(tagIndexUrl(index));
    return html == null ? const [] : Isolate.run(() => parseTagIndex(html));
  }
}
