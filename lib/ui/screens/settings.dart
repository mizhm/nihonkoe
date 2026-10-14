import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logic/i18n.dart';
import '../../state/settings.dart';
import '../l10n.dart';

const _languageNames = {LanguagePref.vi: 'Tiếng Việt', LanguagePref.en: 'English', LanguagePref.ja: '日本語'};

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final accentNames = {
      AccentPref.system: l.accentSystem,
      AccentPref.lavender: l.accentLavender,
      AccentPref.sakura: l.accentSakura,
      AccentPref.ocean: l.accentOcean,
    };
    return Scaffold(
      appBar: AppBar(title: Text(l.tabsSettings)),
      body: ListView(
        children: [
          ListTile(title: Text(l.settingsAppearance, style: TextStyle(color: Theme.of(context).colorScheme.primary))),
          ListTile(
            title: Text(l.settingsTheme),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SegmentedButton<ThemePref>(
                segments: [
                  ButtonSegment(value: ThemePref.system, label: Text(l.settingsThemeSystem)),
                  ButtonSegment(value: ThemePref.light, label: Text(l.settingsThemeLight)),
                  ButtonSegment(value: ThemePref.dark, label: Text(l.settingsThemeDark)),
                ],
                selected: {settings.theme},
                onSelectionChanged: (s) => notifier.setTheme(s.single),
              ),
            ),
          ),
          ListTile(
            title: Text(l.settingsAccent),
            subtitle: Wrap(
              spacing: 8,
              children: [
                for (final accent in AccentPref.values)
                  ChoiceChip(
                    label: Text(accentNames[accent]!),
                    selected: settings.accent == accent,
                    onSelected: (_) => notifier.setAccent(accent),
                  ),
              ],
            ),
          ),
          ListTile(
            title: Text(l.settingsLanguage),
            trailing: DropdownMenu<LanguagePref>(
              initialSelection: settings.language,
              onSelected: (v) => v == null ? null : notifier.setLanguage(v),
              dropdownMenuEntries: [
                for (final lang in LanguagePref.values)
                  DropdownMenuEntry(value: lang, label: _languageNames[lang] ?? l.languageSystem),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
