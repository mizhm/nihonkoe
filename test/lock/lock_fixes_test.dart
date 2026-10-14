import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_platform_interface/local_auth_platform_interface.dart' show AuthMessages;
import 'package:material_ui/material_ui.dart';
import 'package:nihonkoe/app.dart';
import 'package:nihonkoe/lock/authenticator.dart';
import 'package:nihonkoe/state/settings.dart';

import '../helpers.dart';

class FakeLocalAuth extends LocalAuthentication {
  bool? sticky;
  bool? sensitive;
  Object? error;

  @override
  Future<bool> authenticate({
    required String localizedReason,
    Iterable<AuthMessages> authMessages = const <AuthMessages>[],
    bool biometricOnly = false,
    bool sensitiveTransaction = true,
    bool persistAcrossBackgrounding = false,
  }) async {
    sticky = persistAcrossBackgrounding;
    sensitive = sensitiveTransaction;
    if (error case final e?) throw e;
    return true;
  }
}

Future<void> launch(WidgetTester tester, FakeAuthenticator auth, {bool appLock = true}) async {
  await tester.pumpWidget(ProviderScope(
    overrides: await testOverrides(prefs: {'language': 'en', 'appLock': appLock}, authenticator: auth),
    retry: noRetry,
    child: const NihonkoeApp(),
  ));
  await tester.pumpAndSettle();
}

void cycleBackground(WidgetTester tester) {
  for (final s in [AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.paused]) {
    tester.binding.handleAppLifecycleStateChanged(s);
  }
}

void cycleForeground(WidgetTester tester) {
  for (final s in [AppLifecycleState.hidden, AppLifecycleState.inactive, AppLifecycleState.resumed]) {
    tester.binding.handleAppLifecycleStateChanged(s);
  }
}

void main() {
  test('local_auth is called without sticky mode and without the extra face-unlock confirm tap', () async {
    final plugin = FakeLocalAuth();
    expect(await LocalAuthenticator(plugin).authenticate('x'), AuthResult.success);
    expect(plugin.sticky, isFalse);
    expect(plugin.sensitive, isFalse);
    plugin.error = const LocalAuthException(code: LocalAuthExceptionCode.noCredentialsSet);
    expect(await LocalAuthenticator(plugin).authenticate('x'), AuthResult.unavailable);
  });

  testWidgets('a screen lock removed from the phone turns app lock off instead of locking the user out', (tester) async {
    await launch(tester, FakeAuthenticator(results: [AuthResult.unavailable]));
    expect(find.text(en.lockUnlock), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(containerOf(tester).read(settingsProvider).appLock, isFalse);
  });

  testWidgets('authenticating from Settings (PIN screen backgrounds the app) does not re-lock or prompt again', (tester) async {
    final auth = FakeAuthenticator();
    await launch(tester, auth);
    expect(auth.calls, 1);
    await tester.tap(find.text(en.tabsSettings));
    await tester.pumpAndSettle();
    auth.gate = Completer<void>();
    await tester.tap(find.text(en.settingsLock)); // turning it off
    await tester.pump();
    cycleBackground(tester);
    cycleForeground(tester);
    auth.gate!.complete();
    await tester.pumpAndSettle();
    expect(auth.calls, 2);
    expect(find.text(en.lockUnlock), findsNothing);
    expect(containerOf(tester).read(settingsProvider).appLock, isFalse);
  });

  testWidgets('a prompt cancelled by backgrounding is shown again when the app returns', (tester) async {
    final auth = FakeAuthenticator(results: [AuthResult.failed, AuthResult.success])..gate = Completer<void>();
    await launch(tester, auth);
    cycleBackground(tester);
    final gate = auth.gate!;
    auth.gate = null;
    gate.complete(); // the system cancels the prompt while the app is in the background
    await tester.pump();
    cycleForeground(tester);
    await tester.pumpAndSettle();
    expect(auth.calls, 2);
    expect(find.text(en.lockUnlock), findsNothing);
  });

  testWidgets('while locked, a screen reader cannot reach the app underneath', (tester) async {
    await launch(tester, FakeAuthenticator(results: [AuthResult.failed]));
    expect(find.text(en.lockUnlock), findsOneWidget);
    expect(find.bySemanticsLabel(en.tabsHome), findsNothing);
    expect(find.bySemanticsLabel(en.lockUnlock), findsOneWidget);
  });
}
