import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release manifest requests INTERNET (only debug/profile manifests get it from the template)', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(manifest, contains('<uses-permission android:name="android.permission.INTERNET"'));
  });

  test('manifest declares the audio_service service, media button receiver and playback permissions', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    for (final needle in [
      'android.permission.WAKE_LOCK',
      'android.permission.FOREGROUND_SERVICE"',
      'android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK',
      'android.permission.POST_NOTIFICATIONS',
      'com.ryanheise.audioservice.AudioService"',
      'android:foregroundServiceType="mediaPlayback"',
      'com.ryanheise.audioservice.MediaButtonReceiver',
      'android.intent.action.MEDIA_BUTTON',
    ]) {
      expect(manifest, contains(needle), reason: needle);
    }
  });

  test('MainActivity shares the audio_service engine and is a FragmentActivity (local_auth in phase 3)', () {
    final activity = File('android/app/src/main/kotlin/dev/local/nihonkoe/MainActivity.kt').readAsStringSync();
    expect(activity, contains('AudioServiceFragmentActivity'));
  });

  test('local_auth: USE_BIOMETRIC permission and an AppCompat launch theme', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(manifest, contains('android.permission.USE_BIOMETRIC'));
    final styles = File('android/app/src/main/res/values/styles.xml').readAsStringSync();
    expect(styles, contains('name="LaunchTheme" parent="Theme.AppCompat'));
  });

  test('the post-launch theme is AppCompat too (biometric dialog on API 24-27)', () {
    for (final f in ['values', 'values-night']) {
      final styles = File('android/app/src/main/res/$f/styles.xml').readAsStringSync();
      expect(styles, contains('name="NormalTheme" parent="Theme.AppCompat'), reason: f);
    }
  });
}
