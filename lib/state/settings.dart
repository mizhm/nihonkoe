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

enum HomeFeed {
  latest(ListQuery.latest()),
  hotWeek(ListQuery.latest(), ListSort.popularWeek),
  hotMonth(ListQuery.latest(), ListSort.popularMonth),
  requested(ListQuery.category('requested')),
  maniax(ListQuery.category('rating/maniax'));

  const HomeFeed(this.query, [this.fixedSort]);
  final ListQuery query;
  final ListSort? fixedSort; // hot feeds are defined by their order, so the user's sort doesn't apply
}

@immutable
class Settings {
  const Settings({
    this.theme = ThemePref.system,
    this.accent = AccentPref.system,
    this.language = LanguagePref.system,
    this.cardLayout = CardLayout.grid,
    this.homeSort = ListSort.newest,
    this.homeFeed = HomeFeed.latest,
    this.privacy = false,
    this.appLock = false,
  });
  final ThemePref theme;
  final AccentPref accent;
  final LanguagePref language;
  final CardLayout cardLayout;
  final ListSort homeSort;
  final HomeFeed homeFeed;
  final bool privacy; // blur covers, no lock-screen artwork
  final bool appLock;

  Settings copyWith({
    ThemePref? theme,
    AccentPref? accent,
    LanguagePref? language,
    CardLayout? cardLayout,
    ListSort? homeSort,
    HomeFeed? homeFeed,
    bool? privacy,
    bool? appLock,
  }) =>
      Settings(
        theme: theme ?? this.theme,
        accent: accent ?? this.accent,
        language: language ?? this.language,
        cardLayout: cardLayout ?? this.cardLayout,
        homeSort: homeSort ?? this.homeSort,
        homeFeed: homeFeed ?? this.homeFeed,
        privacy: privacy ?? this.privacy,
        appLock: appLock ?? this.appLock,
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
      homeFeed: _byName(HomeFeed.values, p.getString('homeFeed'), HomeFeed.latest),
      privacy: p.getBool('privacy') ?? false,
      appLock: p.getBool('appLock') ?? false,
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
  void setHomeFeed(HomeFeed v) => _save('homeFeed', v.name, state.copyWith(homeFeed: v));

  void setPrivacy(bool v) {
    ref.read(prefsProvider).setBool('privacy', v);
    state = state.copyWith(privacy: v);
  }

  void setAppLock(bool v) {
    ref.read(prefsProvider).setBool('appLock', v);
    state = state.copyWith(appLock: v);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, Settings>(SettingsNotifier.new);
