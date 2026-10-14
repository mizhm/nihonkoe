import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nihonkoe/api/models.dart';
import 'package:nihonkoe/app.dart';
import 'package:nihonkoe/logic/sleep.dart';
import 'package:nihonkoe/player/handler.dart';

import '../helpers.dart';
import '../player_fakes.dart';

const chapters = [Track(title: 'Intro', startSeconds: 0), Track(title: 'Ear licking', startSeconds: 100)];

Future<(NihonkoeAudioHandler, FakeEngine)> openPlayer(WidgetTester tester, {int Function()? now}) async {
  final engine = FakeEngine();
  final handler = makeHandler(engine: engine, now: now);
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(overrides: await testOverrides(handler: handler), retry: noRetry, child: const NihonkoeApp()));
  await handler.playItems([item(1, chapters: chapters), item(2), item(3)]);
  await tester.pumpAndSettle();
  await tester.tap(find.bySemanticsLabel(en.playerOpen('Work 1')));
  await tester.pumpAndSettle();
  return (handler, engine);
}

void main() {
  testWidgets('chapters sheet seeks to the chosen chapter', (tester) async {
    final (_, engine) = await openPlayer(tester);
    await tester.tap(find.byTooltip(en.playerChapters));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ear licking').last);
    await tester.pumpAndSettle();
    expect(engine.position, const Duration(seconds: 100));
  });

  testWidgets('speed sheet sets the rate', (tester) async {
    final (handler, engine) = await openPlayer(tester);
    await tester.tap(find.text('1.0×'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1.5×'));
    await tester.pumpAndSettle();
    expect(handler.snapshot.rate, 1.5);
    expect(engine.speed, 1.5);
  });

  testWidgets('sleep sheet sets minutes, end of chapter, end of work, extend and off', (tester) async {
    final (handler, engine) = await openPlayer(tester, now: () => 0);
    await tester.tap(find.bySemanticsLabel(en.sleepTitle));
    await tester.pumpAndSettle();
    await tester.tap(find.text(en.sleepMinutes(15)));
    await tester.pumpAndSettle();
    expect(handler.snapshot.sleep, const SleepAt(15 * 60000));
    await tester.tap(find.bySemanticsLabel(en.sleepActive(en.sleepMinutes(15))));
    await tester.pumpAndSettle();
    await tester.tap(find.text(en.sleepExtend(10)));
    await tester.pumpAndSettle();
    expect(handler.snapshot.sleep, const SleepAt(25 * 60000));
    await tester.tap(find.text(en.sleepOff));
    await tester.pumpAndSettle();
    expect(handler.snapshot.sleep, const SleepOff());
    await tester.tap(find.bySemanticsLabel(en.sleepTitle));
    await tester.pumpAndSettle();
    await tester.tap(find.text(en.sleepChapterEnd));
    await tester.pumpAndSettle();
    expect(handler.snapshot.sleep, const SleepAtPosition('1:0', 100));
    await tester.tap(find.bySemanticsLabel(en.sleepActive(en.sleepRemainingChapter)));
    await tester.pumpAndSettle();
    await tester.tap(find.text(en.sleepOff));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel(en.sleepTitle));
    await tester.pumpAndSettle();
    await tester.tap(find.text(en.sleepWorkEnd));
    await tester.pumpAndSettle();
    expect(handler.snapshot.sleep, const SleepItemEnd());
    expect(engine.playing, isTrue);
  });

  testWidgets('more sheet toggles shuffle and opens the queue; the queue jumps and removes but never the current item',
      (tester) async {
    final (handler, _) = await openPlayer(tester);
    await tester.tap(find.byTooltip(en.playerMore));
    await tester.pumpAndSettle();
    await tester.tap(find.text(en.playerShuffle));
    await tester.pumpAndSettle();
    expect(handler.snapshot.shuffle, isTrue);
    await tester.tap(find.text(en.playerShuffle));
    await tester.pumpAndSettle();
    await tester.tap(find.text(en.playerQueue));
    await tester.pumpAndSettle();
    expect(find.byTooltip(en.queueRemove('Work 1')), findsNothing, reason: 'the playing item has no remove button');
    await tester.tap(find.byTooltip(en.queueRemove('Work 3')));
    await tester.pumpAndSettle();
    expect([for (final i in handler.snapshot.queue) i.key], ['1:0', '2:0']);
    await tester.tap(find.text('Work 2').last);
    await tester.pumpAndSettle();
    expect(handler.snapshot.current!.key, '2:0');
  });

  testWidgets('more sheet opens the work page', (tester) async {
    await openPlayer(tester);
    await tester.tap(find.byTooltip(en.playerMore));
    await tester.pumpAndSettle();
    await tester.tap(find.text(en.moreOpenWork));
    await tester.pumpAndSettle();
    expect(find.text(en.detailNotFound), findsOneWidget); // mock HTTP 404s the post page
  });
}
