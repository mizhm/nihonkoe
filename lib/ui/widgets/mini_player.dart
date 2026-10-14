import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

import '../../logic/chapters.dart';
import '../../logic/format.dart';
import '../../logic/seek.dart';
import '../../player/handler.dart';
import '../../state/player.dart';
import '../l10n.dart';
import '../links.dart';
import 'cover.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(playerProvider).value;
    final item = snapshot?.current;
    if (snapshot == null || item == null) return const SizedBox.shrink();
    final l = context.l10n;
    final theme = Theme.of(context);
    final handler = ref.read(audioHandlerProvider);
    final playback = ref.watch(playbackProvider).value ?? const PlaybackInfo();
    final duration = playback.duration ?? Duration.zero;
    final error = snapshot.error != null;

    return Material(
      color: theme.colorScheme.surfaceContainer,
      child: Semantics(
        customSemanticsActions: {CustomSemanticsAction(label: l.playerStop): handler.stop},
        child: GestureDetector(
          // Swipe down to stop, like the Expo app's dock.
          onVerticalDragEnd: (d) {
            if ((d.primaryVelocity ?? 0) > 300) handler.stop();
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Only the bar and the subtitle follow the position; the rest rebuilds on state changes.
              Consumer(
                builder: (context, ref, _) {
                  final position = ref.watch(positionProvider).value ?? Duration.zero;
                  final seconds = position.inMilliseconds / 1000;
                  final progress =
                      duration > Duration.zero ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0) : 0.0;
                  return LayoutBuilder(
                    builder: (context, constraints) => GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapUp: duration > Duration.zero
                          ? (d) => handler.seek(Duration(
                              seconds: seekTarget(d.localPosition.dx, constraints.maxWidth, duration.inSeconds.toDouble()).round()))
                          : null,
                      child: Semantics(
                        label: l.playerPosition,
                        value: formatTime(seconds),
                        increasedValue: formatTime(seconds + 30),
                        decreasedValue: formatTime(seconds - 15),
                        onIncrease: () => handler.seekBy(30),
                        onDecrease: () => handler.seekBy(-15),
                        child: SizedBox(
                          height: 12,
                          child: Align(alignment: Alignment.topCenter, child: LinearProgressIndicator(value: progress, minHeight: 3)),
                        ),
                      ),
                    ),
                  );
                },
              ),
              InkWell(
                // The player sits above the tabs; tell it which tab to open pages in.
                onTap: () => context.push(Uri(path: '/player', queryParameters: {'from': branchBaseOf(currentPath(context))}).toString()),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 4, 8),
                  child: Row(
                    children: [
                      SizedBox.square(dimension: 44, child: Cover(url: item.post.cover, borderRadius: BorderRadius.circular(8))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Semantics(
                          button: true,
                          label: l.playerOpen(item.title),
                          excludeSemantics: true,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall),
                              Consumer(
                                builder: (context, ref, _) {
                                  final seconds = (ref.watch(positionProvider).value ?? Duration.zero).inMilliseconds / 1000;
                                  final chapter = chapterIndexAt(item.chapters, seconds);
                                  return Text(
                                    error
                                        ? l.playerErrorShort
                                        : chapter >= 0
                                            ? '${item.chapters[chapter].title} · ${formatTime(seconds)}'
                                            : item.post.cv ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: error ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (error)
                        IconButton(tooltip: l.playerRetry, icon: const Icon(Symbols.refresh), onPressed: handler.retry)
                      else ...[
                        IconButton(tooltip: l.playerPreviousChapter, icon: const Icon(Symbols.skip_previous), onPressed: handler.previousChapter),
                        if (playback.buffering && playback.playing)
                          const SizedBox.square(dimension: 48, child: Padding(padding: EdgeInsets.all(14), child: CircularProgressIndicator(strokeWidth: 2)))
                        else
                          IconButton(
                            tooltip: playback.playing ? l.playerPause : l.playerPlay,
                            icon: Icon(playback.playing ? Symbols.pause : Symbols.play_arrow, fill: 1),
                            onPressed: handler.toggle,
                          ),
                        IconButton(tooltip: l.playerNextChapter, icon: const Icon(Symbols.skip_next), onPressed: handler.nextChapter),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
