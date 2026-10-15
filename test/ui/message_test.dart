import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nihonkoe/api/client.dart';
import 'package:nihonkoe/ui/widgets/message.dart';

import '../helpers.dart';

Widget message(Object error) => Scaffold(body: Message(icon: Symbols.cloud_off, title: 'x', hint: 'hint', onRetry: () {}, error: error));

void main() {
  testWidgets('a Cloudflare captcha offers the WebView; other errors do not', (tester) async {
    await pumpRouted(tester, message(const ChallengeException('https://japaneseasmr.com/')), overrides: await testOverrides());
    await tester.pumpAndSettle();
    expect(find.text(en.challengeOpen), findsOneWidget);
    expect(find.text(en.challengeHint), findsOneWidget);
    await pumpRouted(tester, message(const ApiException('https://japaneseasmr.com/', 500)), overrides: await testOverrides());
    await tester.pumpAndSettle();
    expect(find.text(en.challengeOpen), findsNothing);
    expect(find.text('hint'), findsOneWidget);
  });
}
