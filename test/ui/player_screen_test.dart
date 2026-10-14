import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nihonkoe/api/models.dart';
import 'package:nihonkoe/app.dart';
import 'package:nihonkoe/ui/screens/player.dart';

import '../helpers.dart';
import '../player_fakes.dart';

const chapters = [Track(title: 'Intro', startSeconds: 0), Track(title: 'Ear licking', startSeconds: 100)];

Future<FakeEngine> openPlayer(WidgetTester tester, {FakeEngine? engine}) async {
  final e = engine ?? FakeEngine();
  final handler = makeHandler(engine: e);
  await tester.pumpWidget(ProviderScope(overrides: await testOverrides(handler: handler), retry: noRetry, child: const NihonkoeApp()));
  await handler.playItems([item(1, chapters: chapters), item(2)]);
  await tester.pumpAndSettle();
  await tester.tap(find.bySemanticsLabel(en.playerOpen('Work 1')));
  await tester.pumpAndSettle();
  return e;
}

void main() {
  testWidgets('tapping the mini player opens the player with title, chapter and controls', (tester) async {
    final engine = await openPlayer(tester);
    expect(find.byType(PlayerScreen), findsOneWidget);
    expect(find.text('Work 1'), findsWidgets);
    expect(find.text('Intro'), findsOneWidget);
    await tester.tap(find.byTooltip(en.playerForward30));
    await tester.pumpAndSettle();
    expect(engine.position, const Duration(seconds: 30));
    await tester.tap(find.byTooltip(en.playerBack15));
    await tester.pumpAndSettle();
    expect(engine.position, const Duration(seconds: 15));
    await tester.tap(find.byTooltip(en.playerNextChapter));
    await tester.pumpAndSettle();
    expect(engine.position, const Duration(seconds: 100));
  });

  testWidgets('repeat button cycles and is labelled with the mode', (tester) async {
    await openPlayer(tester);
    await tester.tap(find.byTooltip(en.playerRepeatOff));
    await tester.pumpAndSettle();
    expect(find.byTooltip(en.playerRepeatAll), findsOneWidget);
    await tester.tap(find.byTooltip(en.playerRepeatAll));
    await tester.pumpAndSettle();
    expect(find.byTooltip(en.playerRepeatOne), findsOneWidget);
  });

  testWidgets('an error replaces the slider with a retry row', (tester) async {
    final engine = await openPlayer(tester);
    engine.fail(Exception('Source error'));
    await tester.pumpAndSettle();
    expect(find.text(en.playerError), findsOneWidget);
    expect(find.byType(Slider), findsNothing);
  });

  testWidgets('closing the player returns to the tabs', (tester) async {
    await openPlayer(tester);
    await tester.tap(find.byTooltip(en.playerClose));
    await tester.pumpAndSettle();
    expect(find.byType(PlayerScreen), findsNothing);
  });
}
