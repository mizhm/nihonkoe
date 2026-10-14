import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// A minimal archive page with one post per id.
String listHtml(List<int> ids, {bool next = false}) => '<ul>${ids.map((id) => '<li class="site-archive-post post-$id">'
    '<h2 class="entry-title"><a href="https://japaneseasmr.com/$id/">Post $id</a></h2>'
    '<img data-src="https://pic.weeabo0.xyz/$id.jpg"></li>').join()}</ul>'
    '${next ? '<a class="next page-numbers" href="#">Next</a>' : ''}';

/// Serves [routes] by full URL; anything else is a 404. Requested URLs are appended to [log].
http.Client mockHttp(Map<String, String> routes, {List<String>? log, int status = 200}) => MockClient((req) async {
      final url = req.url.toString();
      log?.add(url);
      final body = routes[url];
      return body == null ? http.Response('', 404) : http.Response.bytes(utf8.encode(body), status);
    });
