import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihonkoe/api/models.dart';
import 'package:nihonkoe/logic/i18n.dart';
import 'package:nihonkoe/logic/layout.dart';
import 'package:nihonkoe/state/core.dart';
import 'package:nihonkoe/state/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> container(Map<String, Object> initial) async {
  SharedPreferences.setMockInitialValues(initial);
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer.test(overrides: [prefsProvider.overrideWithValue(prefs)]);
}

void main() {
  test('defaults when nothing is stored, unknown values fall back', () async {
    final c = await container({'theme': 'neon', 'homeSort': 'comments'});
    final s = c.read(settingsProvider);
    expect(s.theme, ThemePref.system);
    expect(s.accent, AccentPref.system);
    expect(s.language, LanguagePref.system);
    expect(s.cardLayout, CardLayout.grid);
    expect(s.homeSort, ListSort.newest);
  });

  test('setters update state and persist', () async {
    final c = await container({});
    final n = c.read(settingsProvider.notifier)
      ..setTheme(ThemePref.dark)
      ..setAccent(AccentPref.sakura)
      ..setLanguage(LanguagePref.ja)
      ..cycleCardLayout()
      ..setHomeSort(ListSort.popularWeek);
    expect(n.state.theme.mode, ThemeMode.dark);
    final prefs = c.read(prefsProvider);
    expect(prefs.getString('theme'), 'dark');
    expect(prefs.getString('accent'), 'sakura');
    expect(prefs.getString('language'), 'ja');
    expect(prefs.getString('cardLayout'), 'compact');
    expect(prefs.getString('homeSort'), 'popular-week');
  });

  test('stored values are read back on start', () async {
    final c = await container({'accent': 'ocean', 'cardLayout': 'list', 'homeSort': 'popular-month'});
    final s = c.read(settingsProvider);
    expect(s.accent.seed, const Color(0xFF0075DC));
    expect(s.cardLayout, CardLayout.list);
    expect(s.homeSort, ListSort.popularMonth);
  });

  test('retryPolicy retries twice with backoff', () {
    expect(retryPolicy(0, Exception()), const Duration(milliseconds: 500));
    expect(retryPolicy(1, Exception()), const Duration(milliseconds: 1000));
    expect(retryPolicy(2, Exception()), isNull);
  });

  test('privacy and app lock persist', () async {
    final c = await container({});
    c.read(settingsProvider.notifier)
      ..setPrivacy(true)
      ..setAppLock(true);
    final prefs = c.read(prefsProvider);
    expect((prefs.getBool('privacy'), prefs.getBool('appLock')), (true, true));
    final again = await container({'privacy': true, 'appLock': true});
    expect((again.read(settingsProvider).privacy, again.read(settingsProvider).appLock), (true, true));
  });
}
