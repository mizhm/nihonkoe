import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:nihonkoe/api/models.dart';
import 'package:nihonkoe/app.dart';
import 'package:nihonkoe/state/core.dart';
import 'package:nihonkoe/state/settings.dart';

import '../helpers.dart';
import '../player_fakes.dart';

Future<void> openSettings(WidgetTester tester, List<Override> overrides) async {
  tester.view.physicalSize = const Size(1080, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(overrides: overrides, retry: noRetry, child: const NihonkoeApp()));
  await tester.pumpAndSettle();
  await tester.tap(find.text(en.tabsSettings));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('privacy switch toggles the setting', (tester) async {
    await openSettings(tester, await testOverrides());
    await tester.tap(find.text(en.settingsPrivacy));
    await tester.pumpAndSettle();
    expect(containerOf(tester).read(settingsProvider).privacy, isTrue);
  });

  testWidgets('clear image cache runs the clearer and says done', (tester) async {
    var cleared = 0;
    await openSettings(tester, [...await testOverrides(imageCacheClearer: () async => cleared++)]);
    await tester.tap(find.text(en.settingsClearImageCache));
    await tester.pumpAndSettle();
    expect(cleared, 1);
    expect(find.text(en.settingsDone), findsOneWidget);
  });

  testWidgets('reload tags deletes the cached index and fetches it again', (tester) async {
    // Sync I/O: real async file futures never complete inside testWidgets' fake-async zone.
    final dir = Directory.systemTemp.createTempSync('tags');
    addTearDown(() => dir.deleteSync(recursive: true));
    File('${dir.path}/tag-index-tags.json').writeAsStringSync('{}');
    var loads = 0;
    await openSettings(tester, [
      ...await testOverrides(loadTagIndex: (_) async {
        loads++;
        return const [];
      }),
      cacheDirProvider.overrideWith((ref) async => dir),
    ]);
    final before = loads;
    await tester.tap(find.text(en.settingsReloadTags));
    // Each await on real file I/O needs real time, then a fake-async pump for its continuation.
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();
    expect(File('${dir.path}/tag-index-tags.json').existsSync(), isFalse);
    // Riverpod pauses providers of hidden tabs; the home feed re-reads the index once it is shown again.
    await tester.tap(find.text(en.tabsHome));
    await tester.pumpAndSettle();
    expect(loads, greaterThan(before));
  });

  testWidgets('clear listening history asks first and keeps favorites', (tester) async {
    final history = MemoryHistory();
    await history.recordPlay(const PostRef(id: 1, title: 'a'));
    final favorites = MemoryFavorites();
    await favorites.toggle(const PostRef(id: 1, title: 'a'));
    await openSettings(tester, await testOverrides(history: history, favorites: favorites, handler: makeHandler(history: history)));
    await tester.tap(find.text(en.settingsClearHistory));
    await tester.pumpAndSettle();
    expect(find.text(en.libraryClearConfirm), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, en.libraryClear));
    await tester.pumpAndSettle();
    expect(await history.list(), isEmpty);
    expect((await favorites.list()).single.id, 1);
  });
}
