import 'package:dynamic_color/dynamic_color.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/app_localizations.dart';
import 'logic/i18n.dart';
import 'router.dart';
import 'state/privacy.dart';
import 'state/settings.dart';

(ColorScheme, ColorScheme) colorSchemes(AccentPref accent, ColorScheme? dynamicLight, ColorScheme? dynamicDark) {
  if (accent == AccentPref.system && dynamicLight != null && dynamicDark != null) return (dynamicLight, dynamicDark);
  final seed = accent.seed ?? AccentPref.lavender.seed!;
  return (
    ColorScheme.fromSeed(seedColor: seed),
    ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
  );
}

class NihonkoeApp extends ConsumerWidget {
  const NihonkoeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(privacySyncProvider);
    final settings = ref.watch(settingsProvider);
    final router = ref.watch(routerProvider);
    return DynamicColorBuilder(
      builder: (dynamicLight, dynamicDark) {
        final (light, dark) = colorSchemes(settings.accent, dynamicLight, dynamicDark);
        return MaterialApp.router(
          title: 'nihonkoe',
          theme: ThemeData(colorScheme: light),
          darkTheme: ThemeData(colorScheme: dark),
          themeMode: settings.theme.mode,
          locale: settings.language == LanguagePref.system ? null : Locale(settings.language.name),
          localeResolutionCallback: (device, _) =>
              Locale(resolveLanguage(LanguagePref.system, device?.languageCode ?? 'en')),
          localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        );
      },
    );
  }
}
