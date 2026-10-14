import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'player.dart';
import 'settings.dart';

/// Pushes privacy mode to the audio handler (lock-screen artwork). Watched by the app root.
final privacySyncProvider = Provider<void>((ref) {
  ref.watch(audioHandlerProvider).hideArtwork = ref.watch(settingsProvider.select((s) => s.privacy));
});
