import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db.dart';
import '../logic/position.dart';
import '../player/handler.dart';
import 'core.dart';

final audioHandlerProvider = Provider<NihonkoeAudioHandler>((ref) => throw UnimplementedError('overridden in main'));

final playerProvider = StreamProvider<PlayerSnapshot>((ref) => ref.watch(audioHandlerProvider).snapshots);

final playbackProvider = StreamProvider<PlaybackInfo>((ref) => ref.watch(audioHandlerProvider).playback);

final positionProvider = StreamProvider.autoDispose<Duration>((ref) => ref.watch(audioHandlerProvider).positionStream);

final positionsRepoProvider = Provider<PositionsRepo>((ref) => PositionsRepo(ref.watch(dbProvider)));

final savedPositionsProvider = StreamProvider<int>((ref) => ref.watch(audioHandlerProvider).savedPositions);

/// Saved listening position of a work, for "Resume · mm:ss". Re-reads after every position write.
final inProgressProvider = FutureProvider.autoDispose.family<ResumePoint?, int>((ref, postId) {
  ref.watch(savedPositionsProvider);
  return ref.watch(positionsRepoProvider).inProgress(postId);
});

final nowProvider = StreamProvider.autoDispose<DateTime>(
  (ref) => Stream.periodic(const Duration(seconds: 15), (_) => DateTime.now()),
);
