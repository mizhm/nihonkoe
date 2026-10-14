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
  final _auth = LocalAuthentication();

  @override
  Future<bool> isAvailable() => _auth.isDeviceSupported();

  @override
  Future<AuthResult> authenticate(String reason) async {
    try {
      // Device PIN/pattern/password is allowed as a fallback (spec 6.5).
      final ok = await _auth.authenticate(localizedReason: reason, persistAcrossBackgrounding: true);
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
