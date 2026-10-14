import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihonkoe/app.dart';
import 'package:nihonkoe/state/settings.dart';
import 'package:nihonkoe/ui/screens/search.dart';
import 'package:nihonkoe/ui/screens/settings.dart';

import '../helpers.dart';

void main() {
  testWidgets('shell shows four destinations and switches tabs', (tester) async {
    await tester.pumpWidget(ProviderScope(overrides: await testOverrides(), retry: noRetry, child: const NihonkoeApp()));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationDestination), findsNWidgets(4));
    await tester.tap(find.text(en.tabsSearch));
    await tester.pumpAndSettle();
    expect(find.byType(SearchScreen), findsOneWidget);
  });

  testWidgets('settings change the theme mode', (tester) async {
    await tester.pumpWidget(ProviderScope(overrides: await testOverrides(), retry: noRetry, child: const NihonkoeApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.text(en.tabsSettings));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
    await tester.tap(find.text(en.settingsThemeDark));
    await tester.pumpAndSettle();
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
  });

  test('colorSchemes: system uses wallpaper colors, falls back to lavender', () {
    final wallpaper = ColorScheme.fromSeed(seedColor: Colors.green);
    final wallpaperDark = ColorScheme.fromSeed(seedColor: Colors.green, brightness: Brightness.dark);
    expect(colorSchemes(AccentPref.system, wallpaper, wallpaperDark).$1, same(wallpaper));
    final lavender = colorSchemes(AccentPref.lavender, null, null);
    expect(colorSchemes(AccentPref.system, null, null).$1.primary, lavender.$1.primary);
    expect(colorSchemes(AccentPref.sakura, wallpaper, wallpaperDark).$1.primary, isNot(lavender.$1.primary));
    expect(lavender.$2.brightness, Brightness.dark);
  });
}
