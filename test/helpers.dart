import 'dart:convert';
import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nihonkoe/api/models.dart';
import 'package:nihonkoe/l10n/app_localizations.dart';
import 'package:nihonkoe/logic/tags.dart';
import 'package:nihonkoe/state/core.dart';
import 'package:nihonkoe/player/handler.dart';
import 'package:nihonkoe/state/player.dart';
import 'package:nihonkoe/state/posts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'player_fakes.dart';

/// A minimal archive page with one post per id.
String listHtml(List<int> ids, {bool next = false}) =>
    '<ul>${ids.map((id) => '<li class="site-archive-post post-$id">'
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

/// 1×1 transparent PNG.
final transparentPng = Uint8List.fromList(const [
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

AppLocalizations get en => lookupAppLocalizations(const Locale('en'));

/// Riverpod 3 retries failed providers by default; tests want failures to surface at once.
Duration? noRetry(int retryCount, Object error) => null;

/// The container behind a pumped [ProviderScope] (disposed with the widget tree, so cache timers never leak).
ProviderContainer containerOf(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(Navigator).first));

/// Overrides for widget tests: no disk, no real network (unknown URLs 404), empty tag index.
Future<List<Override>> testOverrides({
  http.Client? client,
  Map<String, Object> prefs = const {'language': 'en'},
  List<TagIndexItem> tagIndex = const [],
  Future<List<TagIndexItem>> Function(TagIndex index)? loadTagIndex,
  NihonkoeAudioHandler? handler,
  MemoryPositions? positions,
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final sharedPrefs = await SharedPreferences.getInstance();
  return [
    prefsProvider.overrideWithValue(sharedPrefs),
    httpClientProvider.overrideWithValue(client ?? mockHttp({})),
    imageProviderFactory.overrideWithValue((_) => MemoryImage(transparentPng)),
    audioHandlerProvider.overrideWithValue(handler ?? makeHandler(positions: positions)),
    positionsRepoProvider.overrideWithValue(positions ?? MemoryPositions()),
    tagIndexProvider.overrideWith((ref, index) => loadTagIndex?.call(index) ?? Future.value(tagIndex)),
  ];
}

/// Pumps [child] as the only route of a GoRouter app with localizations.
Future<void> pumpRouted(WidgetTester tester, Widget child, {List<Override> overrides = const []}) async {
  final router = GoRouter(
    routes: [GoRoute(path: '/', builder: (_, _) => child)],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      retry: noRetry,
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('en'),
        localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
}
