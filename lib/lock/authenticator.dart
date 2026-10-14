import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

enum AuthResult { success, failed, lockout, unavailable }

/// The slice of local_auth the lock needs; faked in widget tests.
abstract interface class Authenticator {
  /// Whether the device has a screen lock or biometrics to authenticate with.
  Future<bool> isAvailable();
  Future<AuthResult> authenticate(String reason);
}

class LocalAuthenticator implements Authenticator {
  LocalAuthenticator([LocalAuthentication? auth]) : _auth = auth ?? LocalAuthentication();
  final LocalAuthentication _auth;

  @override
  Future<bool> isAvailable() => _auth.isDeviceSupported();

  @override
  Future<AuthResult> authenticate(String reason) async {
    try {
      // Device PIN/pattern/password is allowed as a fallback (spec 6.5). No sticky mode: the gate re-prompts on
      // resume itself, and sticky mode can leave the call pending forever if the activity is destroyed meanwhile.
      // sensitiveTransaction off: face unlock would otherwise ask for an extra Confirm tap on every unlock.
      final ok = await _auth.authenticate(localizedReason: reason, sensitiveTransaction: false);
      return ok ? AuthResult.success : AuthResult.failed;
    } on LocalAuthException catch (e) {
      return switch (e.code) {
        LocalAuthExceptionCode.temporaryLockout || LocalAuthExceptionCode.biometricLockout => AuthResult.lockout,
        LocalAuthExceptionCode.noCredentialsSet || LocalAuthExceptionCode.noBiometricHardware => AuthResult.unavailable,
        _ => AuthResult.failed,
      };
    }
  }
}

final authenticatorProvider = Provider<Authenticator>((ref) => LocalAuthenticator());

/// True while any prompt is open (lock gate or Settings): the PIN screen backgrounds the app meanwhile.
final authInProgressProvider = Provider<ValueNotifier<bool>>((ref) => ValueNotifier(false));

Future<AuthResult> runAuthentication(WidgetRef ref, String reason) async {
  final busy = ref.read(authInProgressProvider);
  busy.value = true;
  try {
    return await ref.read(authenticatorProvider).authenticate(reason);
  } finally {
    busy.value = false;
  }
}
