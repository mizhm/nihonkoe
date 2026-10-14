import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nihonkoe/player/handler.dart';

import '../player_fakes.dart';

// Behaviour that only shows with just_audio's real event order (modelled in FakeEngine) and the ticker running.
void main() {
  test('a finished work is not saved back as its full length by the next tick', () async {
    final positions = MemoryPositions();
    final engine = FakeEngine();
    final h = makeHandler(engine: engine, positions: positions);
    await h.playItems([item(1)]);
    engine.emitPosition(3000);
    await pumpEventQueue();
    engine.complete();
    await pumpEventQueue();
    h.tickForTest();
    await pumpEventQueue();
    expect(positions.values.containsKey('1:0'), isFalse);
  });

  test("a stale position tick during another work's load never becomes that work's position", () async {
    final positions = MemoryPositions();
    final engine = FakeEngine();
    final h = makeHandler(engine: engine, positions: positions);
    await h.playItems([item(3)]);
    engine.emitPosition(1200);
    await pumpEventQueue();
    engine.loadGate = Completer<void>();
    unawaited(h.playItems([item(1)])); // never played before
    await pumpEventQueue();
    engine.emitPosition(1205); // just_audio still extrapolates work 3
    h.tickForTest();
    await pumpEventQueue();
    expect(positions.values['1:0'] ?? 0, 0);
    expect(positions.values['3:0'], 1200);
  });

  test('a second tap while a load is in flight does not save a bogus position for the first target', () async {
    final positions = MemoryPositions();
    final engine = FakeEngine();
    final h = makeHandler(engine: engine, positions: positions);
    await h.playItems([item(3)]);
    engine.position = const Duration(seconds: 1200);
    engine.loadGate = Completer<void>();
    unawaited(h.playItems([item(1)]));
    await pumpEventQueue();
    engine.loadGate = null;
    await h.playItems([item(2)]);
    expect(positions.values['1:0'] ?? 0, 0, reason: "work 1 was never played; work 3's position must not leak into it");
  });

  test('a playback error pauses, keeps the notification (error state) and freezes the retry position', () async {
    final positions = MemoryPositions();
    final engine = FakeEngine();
    final h = makeHandler(engine: engine, positions: positions);
    await h.playItems([item(1)]);
    engine.emitPosition(321);
    await pumpEventQueue();
    engine.fail(Exception('Source error'));
    await pumpEventQueue();
    expect(engine.playing, isFalse);
    expect(h.playbackState.value.processingState, AudioProcessingState.error);
    engine.position = const Duration(seconds: 12); // stale native position after the error
    h.tickForTest();
    await pumpEventQueue();
    expect(positions.values['1:0'], isNot(12));
    engine.position = Duration.zero;
    await h.retry();
    expect(engine.position, const Duration(seconds: 321));
  });

  test('stop during the final steps of a load never starts audio', () async {
    final engine = FakeEngine()..speedGate = Completer<void>();
    final h = makeHandler(engine: engine);
    final loading = h.playItems([item(1)]);
    await pumpEventQueue();
    await h.stop();
    engine.speedGate!.complete();
    await loading;
    expect(engine.playing, isFalse);
    expect(h.mediaItem.value, isNull);
  });

  test('switching works while playing never plays the new work from 0 before its resume seek', () async {
    final positions = MemoryPositions()..values['1:0'] = 300;
    final engine = FakeEngine();
    final h = makeHandler(engine: engine, positions: positions);
    await h.playItems([item(3)]);
    engine.audibleFrom.clear();
    await h.playItems([item(1)]);
    expect(engine.audibleFrom, [const Duration(seconds: 300)]);
  });

  test('privacy known at start-up hides artwork before the UI exists (headless playback)', () async {
    final h = NihonkoeAudioHandler(
      engine: FakeEngine(),
      positions: MemoryPositions(),
      history: MemoryHistory(),
      tick: false,
      hideArtwork: true,
    );
    await h.playItems([item(1)]);
    expect(h.mediaItem.value!.artUri, isNull);
  });
}
