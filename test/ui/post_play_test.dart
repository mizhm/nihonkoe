import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nihonkoe/api/models.dart';
import 'package:nihonkoe/app.dart';
import 'package:nihonkoe/router.dart';
import 'package:nihonkoe/ui/links.dart';
import 'package:nihonkoe/ui/sheets/post_actions.dart';

import '../helpers.dart';
import '../player_fakes.dart';

final postHtml = File('test/fixtures/post.html').readAsStringSync();
const postUrl = 'https://japaneseasmr.com/150207/';

Future<FakeEngine> openPost(WidgetTester tester, {MemoryPositions? positions}) async {
  tester.view.physicalSize = const Size(1080, 6000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final engine = FakeEngine();
  final p = positions ?? MemoryPositions();
  await tester.pumpWidget(ProviderScope(
    overrides: await testOverrides(
      client: mockHttp({postUrl: postHtml}),
      handler: makeHandler(engine: engine, positions: p),
      positions: p,
    ),
    retry: noRetry,
    child: const NihonkoeApp(),
  ));
  await tester.pumpAndSettle();
  containerOf(tester).read(routerProvider).push(postPath('', 150207));
  await tester.pumpAndSettle();
  return engine;
}

void main() {
  testWidgets('Play starts the work with the Referer header', (tester) async {
    final engine = await openPost(tester);
    await tester.tap(find.widgetWithText(FilledButton, en.detailPlay));
    await tester.pumpAndSettle();
    expect(engine.loads.single.url, 'https://v.weeab0o.xyz/RJ01700554.m3u8');
    expect(engine.loads.single.headers, mediaHeaders);
    expect(engine.playing, isTrue);
  });

  testWidgets('a saved position turns Play into Resume · time', (tester) async {
    await openPost(tester, positions: MemoryPositions()..values['150207:0'] = 754);
    expect(find.widgetWithText(FilledButton, en.detailResume('12:34')), findsOneWidget);
  });

  testWidgets('tapping a chapter plays from its start', (tester) async {
    final engine = await openPost(tester);
    await tester.tap(find.text('02_下から耳を舐め上げる_右'));
    await tester.pumpAndSettle();
    expect(engine.position, const Duration(seconds: 607));
  });

  testWidgets('Add to queue says so', (tester) async {
    await openPost(tester);
    await tester.tap(find.widgetWithText(FilledButton, en.detailAddToQueue));
    await tester.pumpAndSettle();
    expect(find.text(en.queueAdded), findsOneWidget);
  });

  testWidgets('long-press Play now / Play next load the work', (tester) async {
    final engine = FakeEngine();
    final handler = makeHandler(engine: engine);
    await pumpRouted(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => showPostActions(context, const PostRef(id: 150207, title: 'T')),
              child: const Text('open'),
            ),
          ),
        ),
      ),
      overrides: await testOverrides(client: mockHttp({postUrl: postHtml}), handler: handler),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(en.actionsPlayNow));
    await tester.pumpAndSettle();
    expect(handler.snapshot.current!.key, '150207:0');
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(en.actionsPlayNext));
    await tester.pumpAndSettle();
    expect(find.text(en.queueNext), findsOneWidget);
  });

  testWidgets('a work without audio says so instead of playing', (tester) async {
    await pumpRouted(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(onPressed: () => showPostActions(context, const PostRef(id: 1, title: 'T')), child: const Text('open')),
        ),
      ),
      overrides: await testOverrides(client: mockHttp({'https://japaneseasmr.com/1/': '<h1 class="page-title">T</h1>'})),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(en.actionsPlayNow));
    await tester.pumpAndSettle();
    expect(find.text(en.detailNoStream), findsOneWidget);
  });

  testWidgets('Resume continues the part that was left, not part 1', (tester) async {
    tester.view.physicalSize = const Size(1080, 6000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const twoParts = '<h1 class="page-title">Two parts</h1>'
        '<audio><source src="https://v.weeab0o.xyz/A.mp3"></audio><audio><source src="https://v.weeab0o.xyz/B.mp3"></audio>';
    final engine = FakeEngine();
    final positions = MemoryPositions()..values['7:1'] = 754;
    await tester.pumpWidget(ProviderScope(
      overrides: await testOverrides(
        client: mockHttp({'https://japaneseasmr.com/7/': twoParts}),
        handler: makeHandler(engine: engine, positions: positions),
        positions: positions,
      ),
      retry: noRetry,
      child: const NihonkoeApp(),
    ));
    await tester.pumpAndSettle();
    containerOf(tester).read(routerProvider).push(postPath('', 7));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, en.detailResume('12:34')));
    await tester.pumpAndSettle();
    expect(engine.loads.single.url, 'https://v.weeab0o.xyz/B.mp3');
    expect(engine.position, const Duration(seconds: 754));
  });
}
