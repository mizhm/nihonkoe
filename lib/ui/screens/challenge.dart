import 'package:material_ui/material_ui.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../api/browser.dart';
import '../l10n.dart';

/// The site in a WebView, as in Mihon. From an error it closes itself once the Cloudflare check is passed;
/// from a menu it stays open for browsing (and passing a captcha before one blocks a list).
class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key, required this.url, this.title, this.closeWhenPassed = true});
  final String url;
  final String? title;
  final bool closeWhenPassed;

  static Future<void> open(BuildContext context, String url, {String? title, bool closeWhenPassed = true}) =>
      Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
          builder: (_) => ChallengeScreen(url: url, title: title, closeWhenPassed: closeWhenPassed)));

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  WebViewController? _web;

  @override
  void initState() {
    super.initState();
    challengeWebView().then((web) async {
      await web.setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) async {
          if (widget.closeWhenPassed && !await isChallengePage(web) && mounted) Navigator.of(context).pop();
        },
      ));
      await web.loadRequest(Uri.parse(widget.url));
      if (mounted) setState(() => _web = web);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.title ?? (widget.closeWhenPassed ? context.l10n.challengeTitle : Uri.parse(widget.url).host), maxLines: 1, overflow: TextOverflow.ellipsis)),
        body: _web == null ? const Center(child: CircularProgressIndicator()) : WebViewWidget(controller: _web!),
      );
}
