import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nihonkoe/api/models.dart';
import 'package:nihonkoe/app.dart';
import 'package:nihonkoe/ui/screens/post.dart';
import 'package:nihonkoe/ui/sheets/post_actions.dart';
import 'package:nihonkoe/ui/widgets/cover.dart';

import '../helpers.dart';
import '../player_fakes.dart';

Future<FakeEngine> start(WidgetTester tester, {String tab = ''}) async {
  final engine = FakeEngine();
  final handler = makeHandler(engine: engine);
  await tester.pumpWidget(ProviderScope(overrides: await testOverrides(handler: handler), retry: noRetry, child: const NihonkoeApp()));
  await tester.pumpAndSettle();
  if (tab.isNotEmpty) {
    await tester.tap(find.text(tab));
    await tester.pumpAndSettle();
  }
  await handler.playItems([item(1)]);
  await tester.pumpAndSettle();
  return engine;
}

void main() {
  testWidgets('the back-15 button does not show a "10" icon', (tester) async {
    await start(tester);
    await tester.tap(find.bySemanticsLabel(en.playerOpen('Work 1')));
    await tester.pumpAndSettle();
    final back = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Symbols.replay));
    expect(back.tooltip, en.playerBack15);
    expect(find.byIcon(Symbols.replay_10), findsNothing);
  });

  testWidgets('More → Open work opens the page in the tab the player was opened from', (tester) async {
    await start(tester, tab: en.tabsSearch);
    await tester.tap(find.bySemanticsLabel(en.playerOpen('Work 1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(en.playerMore));
    await tester.pumpAndSettle();
    await tester.tap(find.text(en.moreOpenWork));
    await tester.pumpAndSettle();
    expect(GoRouterState.of(tester.element(find.byType(PostScreen))).matchedLocation, '/search/post/1');
  });

  testWidgets('position ticks rebuild only the time-dependent parts', (tester) async {
    final engine = await start(tester);
    final miniCover = tester.widget<Cover>(find.byType(Cover).first);
    final bar = tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).value;
    engine.emitPosition(12);
    await tester.pump(); // stream event → provider
    await tester.pump(); // rebuild
    expect(tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).value, isNot(bar), reason: 'the tick arrived');
    expect(identical(tester.widget<Cover>(find.byType(Cover).first), miniCover), isTrue, reason: 'mini player');
    await tester.tap(find.bySemanticsLabel(en.playerOpen('Work 1')));
    await tester.pumpAndSettle();
    final playerCover = tester.widget<Cover>(find.byType(Cover).last);
    engine.emitPosition(13);
    await tester.pump(); // stream event → provider
    await tester.pump(); // rebuild
    expect(identical(tester.widget<Cover>(find.byType(Cover).last), playerCover), isTrue, reason: 'player screen');
  });

  testWidgets('the mini player progress bar can be adjusted with a screen reader', (tester) async {
    final engine = await start(tester);
    final node = tester.getSemantics(find.bySemanticsLabel(en.playerPosition));
    expect(node.getSemanticsData().hasAction(SemanticsAction.increase), isTrue);
    tester.semantics.increase(find.semantics.byLabel(en.playerPosition));
    await tester.pumpAndSettle();
    expect(engine.position, const Duration(seconds: 30));
  });

  testWidgets('long-press Play now continues the part that was left', (tester) async {
    const twoParts = '<h1 class="page-title">Two parts</h1>'
        '<audio><source src="https://v.weeab0o.xyz/A.mp3"></audio><audio><source src="https://v.weeab0o.xyz/B.mp3"></audio>';
    final engine = FakeEngine();
    final positions = MemoryPositions()..values['7:1'] = 754;
    await pumpRouted(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(onPressed: () => showPostActions(context, const PostRef(id: 7, title: 'T')), child: const Text('open')),
        ),
      ),
      overrides: await testOverrides(
        client: mockHttp({'https://japaneseasmr.com/7/': twoParts}),
        handler: makeHandler(engine: engine, positions: positions),
        positions: positions,
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(en.actionsPlayNow));
    await tester.pumpAndSettle();
    expect(engine.loads.single.url, 'https://v.weeab0o.xyz/B.mp3');
  });
}
