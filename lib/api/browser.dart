import 'dart:async';
import 'dart:convert';

import 'package:webview_flutter/webview_flutter.dart';

import 'client.dart';

const _challengeTitle = 'Just a moment...';

/// Every WebView sends the same user agent: Cloudflare's clearance cookie is only honored with the agent that earned it.
/// Dropping "; wv" (as Mihon does) makes Cloudflare challenge the WebView less often.
Future<WebViewController> challengeWebView() async {
  final web = WebViewController()..setJavaScriptMode(JavaScriptMode.unrestricted);
  final ua = await web.getUserAgent();
  if (ua != null) await web.setUserAgent(ua.replaceAll('; wv', ''));
  return web;
}

Future<bool> isChallengePage(WebViewController web) async => await web.getTitle() == _challengeTitle;

/// Loads [url] in an off-screen WebView so Cloudflare's JS challenge can run, then returns the page HTML
/// (null for a 404). Throws [ChallengeException] when the challenge needs a person (captcha).
Future<String?> browserFetch(String url, {Duration timeout = const Duration(seconds: 20)}) async {
  final done = Completer<String?>();
  var notFound = false;
  final web = await challengeWebView();
  await web.setNavigationDelegate(NavigationDelegate(
    onHttpError: (e) {
      if (e.request?.uri.toString() == url && e.response?.statusCode == 404) notFound = true;
    },
    onPageFinished: (_) async {
      if (done.isCompleted) return;
      // The challenge page reloads the real URL by itself once solved.
      if (await isChallengePage(web)) return;
      if (notFound) return done.complete(null);
      final html = await web.runJavaScriptReturningResult('document.documentElement.outerHTML');
      // Android hands the string back JSON-encoded.
      if (!done.isCompleted) done.complete(html is String && html.startsWith('"') ? jsonDecode(html) as String : '$html');
    },
    onWebResourceError: (e) {
      if ((e.isForMainFrame ?? true) && !done.isCompleted) done.completeError(e);
    },
  ));
  await web.loadRequest(Uri.parse(url));
  return done.future
      .timeout(timeout, onTimeout: () => throw ChallengeException(url))
      .whenComplete(() => web.loadHtmlString(''));
}
