import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nihonkoe/app.dart';
import 'package:nihonkoe/lock/authenticator.dart';
import 'package:nihonkoe/state/settings.dart';

import '../helpers.dart';

Future<void> launch(WidgetTester tester, FakeAuthenticator auth, {bool appLock = true}) async {
  await tester.pumpWidget(ProviderScope(
    overrides: await testOverrides(prefs: {'language': 'en', 'appLock': appLock}, authenticator: auth),
    retry: noRetry,
    child: const NihonkoeApp(),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('with app lock off the app opens without prompting', (tester) async {
    final auth = FakeAuthenticator();
    await launch(tester, auth, appLock: false);
    expect(auth.calls, 0);
    expect(find.text(en.lockUnlock), findsNothing);
  });

  testWidgets('cold start prompts; success reveals the app', (tester) async {
    final auth = FakeAuthenticator();
    await launch(tester, auth);
    expect(auth.calls, 1);
    expect(find.text(en.lockUnlock), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('a cancelled prompt keeps the app covered; Unlock tries again', (tester) async {
    final auth = FakeAuthenticator(results: [AuthResult.failed, AuthResult.success]);
    await launch(tester, auth);
    expect(find.text(en.lockUnlock), findsOneWidget);
    await tester.tap(find.text(en.lockUnlock));
    await tester.pumpAndSettle();
    expect(find.text(en.lockUnlock), findsNothing);
  });

  testWidgets('lockout shows its message and stays locked', (tester) async {
    await launch(tester, FakeAuthenticator(results: [AuthResult.lockout]));
    expect(find.text(en.lockLockout), findsOneWidget);
    expect(find.text(en.lockUnlock), findsOneWidget);
  });

  testWidgets('returning from background locks and prompts again', (tester) async {
    // Frames are off while paused, so the cover is checked after resuming: the second prompt is cancelled.
    final auth = FakeAuthenticator(results: [AuthResult.success, AuthResult.failed]);
    await launch(tester, auth);
    expect(find.text(en.lockUnlock), findsNothing);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(auth.calls, 2);
    expect(find.text(en.lockUnlock), findsOneWidget);
  });

  testWidgets('the PIN screen backgrounding the app during a prompt does not re-lock in a loop', (tester) async {
    final auth = FakeAuthenticator()..gate = Completer<void>();
    await launch(tester, auth);
    // System credential activity covers the app while the prompt is open.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    auth.gate!.complete();
    await tester.pumpAndSettle();
    expect(auth.calls, 1);
    expect(find.text(en.lockUnlock), findsNothing);
  });

  testWidgets('turning the lock on without a device screen lock is refused', (tester) async {
    final auth = FakeAuthenticator(available: false);
    await launch(tester, auth, appLock: false);
    await tester.tap(find.text(en.tabsSettings));
    await tester.pumpAndSettle();
    await tester.tap(find.text(en.settingsLock));
    await tester.pumpAndSettle();
    expect(find.text(en.lockUnavailableTitle), findsOneWidget);
    await tester.tap(find.text(MaterialLocalizations.of(tester.element(find.text(en.lockUnavailableTitle))).okButtonLabel));
    await tester.pumpAndSettle();
    expect(containerOf(tester).read(settingsProvider).appLock, isFalse);
  });

  testWidgets('turning the lock on and off requires authentication', (tester) async {
    final auth = FakeAuthenticator(results: [AuthResult.success, AuthResult.failed]);
    await launch(tester, auth, appLock: false);
    await tester.tap(find.text(en.tabsSettings));
    await tester.pumpAndSettle();
    await tester.tap(find.text(en.settingsLock));
    await tester.pumpAndSettle();
    expect(containerOf(tester).read(settingsProvider).appLock, isTrue);
    await tester.tap(find.text(en.settingsLock));
    await tester.pumpAndSettle();
    expect(containerOf(tester).read(settingsProvider).appLock, isTrue, reason: 'a failed prompt keeps it on');
  });
}
