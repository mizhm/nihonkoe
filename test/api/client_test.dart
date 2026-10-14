import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nihonkoe/api/client.dart';
import 'package:nihonkoe/api/models.dart';

void main() {
  test('listPosts parses the page and sends a browser user agent', () async {
    late http.Request seen;
    final client = ApiClient(MockClient((req) async {
      seen = req;
      return http.Response.bytes(utf8.encode('<ul><li class="site-archive-post post-5"><h2 class="entry-title"><a>声</a></h2></li></ul>'), 200);
    }));
    final page = await client.listPosts(const ListQuery.tag('耳かき'), page: 2);
    expect(seen.url.toString(), 'https://japaneseasmr.com/tag/%E8%80%B3%E3%81%8B%E3%81%8D/page/2/');
    expect(seen.headers['User-Agent'], startsWith('Mozilla/5.0'));
    expect(page.items.single.title, '声');
    expect(page.page, 2);
  });

  test('a 404 past the last page is an empty final page', () async {
    final client = ApiClient(MockClient((_) async => http.Response('', 404)));
    final page = await client.listPosts(const ListQuery.latest(), page: 99);
    expect(page.items, isEmpty);
    expect(page.hasNext, isFalse);
    expect(await client.getPost(1), isNull);
  });

  test('a Cloudflare 403 throws ApiException', () async {
    final client = ApiClient(MockClient((_) async => http.Response('Just a moment...', 403)));
    expect(client.listPosts(const ListQuery.latest()), throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 403)));
  });

  test('listTagIndex fetches /tags/ and parses in a background isolate', () async {
    final client = ApiClient(MockClient((req) async {
      expect(req.url.toString(), 'https://japaneseasmr.com/tags/');
      return http.Response.bytes(
          utf8.encode('<a href="https://japaneseasmr.com/tag/asmr/" title="(7)"><span class="tag-groups-label">ASMR</span></a>'), 200);
    }));
    expect(await client.listTagIndex(TagIndex.tags), const [TagIndexEntry(slug: 'asmr', name: 'ASMR', count: 7)]);
  });
}
