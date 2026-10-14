import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release manifest requests INTERNET (only debug/profile manifests get it from the template)', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(manifest, contains('<uses-permission android:name="android.permission.INTERNET"'));
  });
}
