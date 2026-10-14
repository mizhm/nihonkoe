import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/models.dart';
import '../logic/i18n.dart';
import '../logic/layout.dart';
import 'core.dart';

enum ThemePref {
  system(ThemeMode.system),
  light(ThemeMode.light),
  dark(ThemeMode.dark);

  const ThemePref(this.mode);
  final ThemeMode mode;
}

enum AccentPref {
  system(null), // wallpaper colors (Material You), lavender where unavailable
  lavender(Color(0xFF7552DB)),
  sakura(Color(0xFFBF2A82)),
  ocean(Color(0xFF0075DC));

  const AccentPref(this.seed);
  final Color? seed;
}

@immutable
class Settings {
  const Settings({
    this.theme = ThemePref.system,
    this.accent = AccentPref.system,
    this.language = LanguagePref.system,
    this.cardLayout = CardLayout.grid,
    this.homeSort = ListSort.newest,
  });
  final ThemePref theme;
  final AccentPref accent;
  final LanguagePref language;
  final CardLayout cardLayout;
  final ListSort homeSort;

  Settings copyWith({ThemePref? theme, AccentPref? accent, LanguagePref? language, CardLayout? cardLayout, ListSort? homeSort}) =>
      Settings(
        theme: theme ?? this.theme,
        accent: accent ?? this.accent,
        language: language ?? this.language,
        cardLayout: cardLayout ?? this.cardLayout,
        homeSort: homeSort ?? this.homeSort,
      );
}

T _byName<T extends Enum>(List<T> values, String? name, T fallback) => values.asNameMap()[name] ?? fallback;

class SettingsNotifier extends Notifier<Settings> {
  @override
  Settings build() {
    final p = ref.watch(prefsProvider);
    return Settings(
      theme: _byName(ThemePref.values, p.getString('theme'), ThemePref.system),
      accent: _byName(AccentPref.values, p.getString('accent'), AccentPref.system),
      language: _byName(LanguagePref.values, p.getString('language'), LanguagePref.system),
      cardLayout: toCardLayout(p.getString('cardLayout')),
      homeSort: toListSort(p.getString('homeSort')),
    );
  }

  void _save(String key, String value, Settings next) {
    ref.read(prefsProvider).setString(key, value);
    state = next;
  }

  void setTheme(ThemePref v) => _save('theme', v.name, state.copyWith(theme: v));
  void setAccent(AccentPref v) => _save('accent', v.name, state.copyWith(accent: v));
  void setLanguage(LanguagePref v) => _save('language', v.name, state.copyWith(language: v));
  void cycleCardLayout() {
    final next = state.cardLayout.next;
    _save('cardLayout', next.name, state.copyWith(cardLayout: next));
  }

  void setHomeSort(ListSort v) => _save('homeSort', v.id, state.copyWith(homeSort: v));
}

final settingsProvider = NotifierProvider<SettingsNotifier, Settings>(SettingsNotifier.new);
