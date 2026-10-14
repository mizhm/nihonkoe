import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihonkoe/app.dart';
import 'package:nihonkoe/ui/widgets/mini_player.dart';

import '../helpers.dart';
import '../player_fakes.dart';

void main() {
  testWidgets('hidden until something plays, then shows title and toggles playback', (tester) async {
    final engine = FakeEngine();
    final handler = makeHandler(engine: engine);
    await tester.pumpWidget(ProviderScope(overrides: await testOverrides(handler: handler), retry: noRetry, child: const NihonkoeApp()));
    await tester.pumpAndSettle();
    expect(find.byType(MiniPlayer), findsOneWidget);
    expect(find.text('Work 1'), findsNothing);
    await handler.playItems([item(1)]);
    await tester.pumpAndSettle();
    expect(find.text('Work 1'), findsOneWidget);
    await tester.tap(find.byTooltip(en.playerPause));
    await tester.pumpAndSettle();
    expect(engine.playing, isFalse);
    expect(find.byTooltip(en.playerPlay), findsOneWidget);
  });

  testWidgets('swiping down stops playback and hides the mini player', (tester) async {
    final handler = makeHandler();
    await tester.pumpWidget(ProviderScope(overrides: await testOverrides(handler: handler), retry: noRetry, child: const NihonkoeApp()));
    await handler.playItems([item(1)]);
    await tester.pumpAndSettle();
    await tester.fling(find.text('Work 1'), const Offset(0, 200), 1500);
    await tester.pumpAndSettle();
    expect(handler.snapshot.current, isNull);
    expect(find.text('Work 1'), findsNothing);
  });

  testWidgets('a playback error shows a retry button', (tester) async {
    final engine = FakeEngine()..nextLoadError = Exception('403');
    final handler = makeHandler(engine: engine);
    await tester.pumpWidget(ProviderScope(overrides: await testOverrides(handler: handler), retry: noRetry, child: const NihonkoeApp()));
    await handler.playItems([item(1)]);
    await tester.pumpAndSettle();
    expect(find.text(en.playerErrorShort), findsOneWidget);
    await tester.tap(find.byTooltip(en.playerRetry));
    await tester.pumpAndSettle();
    expect(engine.playing, isTrue);
  });
}
