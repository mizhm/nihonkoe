import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const res = 'android/app/src/main/res';

void main() {
  test('launcher icon is the 声 logo: adaptive with foreground, white background and themed monochrome', () {
    final adaptive = File('$res/mipmap-anydpi-v26/ic_launcher.xml').readAsStringSync();
    expect(adaptive, contains('<foreground'));
    expect(adaptive, contains('<monochrome'));
    for (final d in ['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi']) {
      expect(File('$res/mipmap-$d/ic_launcher.png').existsSync(), isTrue, reason: d);
      expect(File('$res/drawable-$d/ic_launcher_foreground.png').existsSync(), isTrue, reason: d);
    }
  });

  test('splash shows the logo on white, also with the Android 12 splash API', () {
    expect(File('$res/drawable/launch_background.xml').readAsStringSync(), contains('@drawable/splash'));
    expect(File('$res/values-v31/styles.xml').readAsStringSync(), contains('windowSplashScreenAnimatedIcon'));
  });

  test('the media notification uses a white status-bar icon, not the launcher icon', () {
    for (final d in ['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi']) {
      expect(File('$res/drawable-$d/ic_stat_nihonkoe.png').existsSync(), isTrue, reason: d);
    }
    expect(File('lib/main.dart').readAsStringSync(), contains("androidNotificationIcon: 'drawable/ic_stat_nihonkoe'"));
  });
}
