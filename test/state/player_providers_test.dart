import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihonkoe/state/player.dart';

import '../player_fakes.dart';

void main() {
  test('playerProvider mirrors the handler; inProgressProvider re-reads after playback changes', () async {
    final positions = MemoryPositions()..values['1:0'] = 42;
    final engine = FakeEngine();
    final handler = makeHandler(engine: engine, positions: positions);
    final c = ProviderContainer.test(overrides: [
      audioHandlerProvider.overrideWithValue(handler),
      positionsRepoProvider.overrideWithValue(positions),
    ]);
    c.listen(playerProvider, (_, _) {});
    c.listen(inProgressProvider(1), (_, _) {});
    expect((await c.read(inProgressProvider(1).future))?.seconds, 42);
    await handler.playItems([item(1)]);
    await pumpEventQueue();
    expect(c.read(playerProvider).value!.current!.key, '1:0');
    engine.position = const Duration(seconds: 99); // listened further, then stopped
    await handler.stop();
    await pumpEventQueue();
    expect((await c.read(inProgressProvider(1).future))?.seconds, 99);
  });

  test('the Resume time follows a pause, not only a change of item', () async {
    final positions = MemoryPositions();
    final engine = FakeEngine();
    final handler = makeHandler(engine: engine, positions: positions);
    final c = ProviderContainer.test(overrides: [
      audioHandlerProvider.overrideWithValue(handler),
      positionsRepoProvider.overrideWithValue(positions),
    ]);
    c.listen(inProgressProvider(1), (_, _) {});
    await handler.playItems([item(1)]);
    await pumpEventQueue();
    engine.position = const Duration(seconds: 30);
    await handler.pause();
    await pumpEventQueue();
    expect((await c.read(inProgressProvider(1).future))?.seconds, 30);
  });
}
