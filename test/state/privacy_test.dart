import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihonkoe/state/core.dart';
import 'package:nihonkoe/state/player.dart';
import 'package:nihonkoe/state/privacy.dart';
import 'package:nihonkoe/state/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../player_fakes.dart';

void main() {
  test('privacy mode drops the notification artwork, also for the item already playing', () async {
    SharedPreferences.setMockInitialValues({});
    final handler = makeHandler();
    final c = ProviderContainer.test(overrides: [
      prefsProvider.overrideWithValue(await SharedPreferences.getInstance()),
      audioHandlerProvider.overrideWithValue(handler),
    ]);
    c.listen(privacySyncProvider, (_, _) {});
    await handler.playItems([item(1)]);
    expect(handler.mediaItem.value!.artUri, isNotNull);
    c.read(settingsProvider.notifier).setPrivacy(true);
    c.read(privacySyncProvider);
    expect(handler.mediaItem.value!.artUri, isNull);
    await handler.playItems([item(2)]);
    expect(handler.mediaItem.value!.artUri, isNull);
    c.read(settingsProvider.notifier).setPrivacy(false);
    c.read(privacySyncProvider);
    expect(handler.mediaItem.value!.artUri, isNotNull);
  });
}
