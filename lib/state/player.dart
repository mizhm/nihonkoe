import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db.dart';
import '../player/handler.dart';
import 'core.dart';

final audioHandlerProvider = Provider<NihonkoeAudioHandler>((ref) => throw UnimplementedError('overridden in main'));

final playerProvider = StreamProvider<PlayerSnapshot>((ref) => ref.watch(audioHandlerProvider).snapshots);

final playbackProvider = StreamProvider<PlaybackInfo>((ref) => ref.watch(audioHandlerProvider).playback);

final positionProvider = StreamProvider.autoDispose<Duration>((ref) => ref.watch(audioHandlerProvider).positionStream);

final positionsRepoProvider = Provider<PositionsRepo>((ref) => PositionsRepo(ref.watch(dbProvider)));

/// Saved listening position of a work, for "Resume · mm:ss". Re-reads when the playing item or queue changes.
final inProgressProvider = FutureProvider.autoDispose.family<double?, int>((ref, postId) {
  ref.watch(playerProvider.select((s) => (s.value?.current?.key, s.value?.queue.length)));
  return ref.watch(positionsRepoProvider).inProgress(postId);
});

final nowProvider = StreamProvider.autoDispose<DateTime>(
  (ref) => Stream.periodic(const Duration(seconds: 15), (_) => DateTime.now()),
);
