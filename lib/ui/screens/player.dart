import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
// Flutter's widgets library has its own RepeatMode (animations); ours is the queue repeat mode.
import 'package:material_ui/material_ui.dart' hide RepeatMode;

import '../../logic/chapters.dart';
import '../../logic/format.dart';
import '../../logic/queue.dart';
import '../../logic/sleep.dart';
import '../../player/handler.dart';
import '../../state/player.dart';
import '../l10n.dart';
import '../sheets/chapters.dart';
import '../sheets/more.dart';
import '../sheets/sleep_timer.dart';
import '../sheets/speed.dart';
import '../sleep_text.dart';
import '../widgets/cover.dart';
import '../widgets/message.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key, this.base = ''});

  /// The tab root the player was opened from ('' for home), where "Open work" pushes the post page.
  final String base;

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final snapshot = ref.watch(playerProvider).value ?? const PlayerSnapshot();
    final item = snapshot.current;
    final handler = ref.read(audioHandlerProvider);
    if (item == null) {
      return Scaffold(appBar: AppBar(), body: Message(icon: Symbols.music_note, title: l.playerNothing));
    }
    final playback = ref.watch(playbackProvider).value ?? const PlaybackInfo();
    final duration = (playback.duration ?? Duration.zero).inMilliseconds / 1000;
    ref.watch(nowProvider); // rebuild every 15 s so the remaining minutes count down
    final remaining = sleepRemaining(snapshot.sleep, handler.now());
    final timer = remaining == null ? null : sleepText(remaining, l);
    final repeatLabel = switch (snapshot.repeat) {
      RepeatMode.off => l.playerRepeatOff,
      RepeatMode.all => l.playerRepeatAll,
      RepeatMode.one => l.playerRepeatOne,
    };

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(tooltip: l.playerClose, icon: const Icon(Symbols.keyboard_arrow_down), onPressed: () => Navigator.pop(context)),
        title: Text(l.playerNowPlaying, style: theme.textTheme.labelLarge),
        centerTitle: true,
        actions: [
          if (item.chapters.isNotEmpty)
            IconButton(tooltip: l.playerChapters, icon: const Icon(Symbols.format_list_bulleted), onPressed: () => showChaptersSheet(context)),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: Cover(url: item.post.cover, aspectRatio: 4 / 3, borderRadius: BorderRadius.circular(28))),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleLarge),
                  Consumer(
                    builder: (context, ref, _) {
                      final chapter = chapterIndexAt(
                        item.chapters,
                        (ref.watch(positionProvider).value ?? Duration.zero).inMilliseconds / 1000,
                      );
                      return Text(
                        chapter >= 0 ? item.chapters[chapter].title : item.post.cv ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      );
                    },
                  ),
                ],
              ),
              if (snapshot.error != null)
                Card.filled(
                  child: ListTile(
                    title: Text(l.playerError, style: TextStyle(color: theme.colorScheme.error)),
                    trailing: FilledButton.tonal(onPressed: handler.retry, child: Text(l.commonRetry)),
                  ),
                )
              else
                _PositionSlider(duration: duration),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(tooltip: l.playerBack15, iconSize: 28, icon: const Icon(Symbols.replay), onPressed: () => handler.seekBy(-15)),
                  IconButton(tooltip: l.playerPreviousChapter, iconSize: 32, icon: const Icon(Symbols.skip_previous, fill: 1), onPressed: handler.previousChapter),
                  FloatingActionButton.large(
                    tooltip: playback.playing ? l.playerPause : l.playerPlay,
                    onPressed: handler.toggle,
                    child: playback.buffering
                        ? const CircularProgressIndicator()
                        : Icon(playback.playing ? Symbols.pause : Symbols.play_arrow, fill: 1, size: 40),
                  ),
                  IconButton(tooltip: l.playerNextChapter, iconSize: 32, icon: const Icon(Symbols.skip_next, fill: 1), onPressed: handler.nextChapter),
                  IconButton(tooltip: l.playerForward30, iconSize: 28, icon: const Icon(Symbols.forward_30), onPressed: () => handler.seekBy(30)),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    tooltip: repeatLabel,
                    isSelected: snapshot.repeat != RepeatMode.off,
                    icon: Icon(snapshot.repeat == RepeatMode.one ? Symbols.repeat_one : Symbols.repeat),
                    onPressed: handler.cycleRepeat,
                  ),
                  TextButton(
                    onPressed: () => showSpeedSheet(context),
                    child: Semantics(label: l.playerSpeed(snapshot.rate), excludeSemantics: true, child: Text('${snapshot.rate}×')),
                  ),
                  TextButton.icon(
                    onPressed: () => showSleepTimerSheet(context),
                    icon: Icon(Symbols.bedtime, fill: timer == null ? 0 : 1),
                    label: Semantics(
                      label: timer == null ? l.sleepTitle : l.sleepActive(timer),
                      excludeSemantics: true,
                      child: Text(timer ?? ''),
                    ),
                  ),
                  Badge(
                    isLabelVisible: snapshot.shuffle,
                    smallSize: 6,
                    child: IconButton(tooltip: l.playerMore, icon: const Icon(Symbols.more_horiz), onPressed: () => showMoreSheet(context, base: widget.base)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The only part of the player that follows the position (~5 updates a second), so the rest stays put.
class _PositionSlider extends ConsumerStatefulWidget {
  const _PositionSlider({required this.duration});
  final double duration;

  @override
  ConsumerState<_PositionSlider> createState() => _PositionSliderState();
}

class _PositionSliderState extends ConsumerState<_PositionSlider> {
  double? _scrub;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final duration = widget.duration;
    final position = _scrub ?? (ref.watch(positionProvider).value ?? Duration.zero).inMilliseconds / 1000;
    return Column(
      children: [
        Slider(
          value: position.clamp(0, duration > 0 ? duration : 1),
          max: duration > 0 ? duration : 1,
          semanticFormatterCallback: (v) => '${l.playerPosition} ${formatTime(v)}',
          onChanged: duration > 0 ? (v) => setState(() => _scrub = v) : null,
          onChangeEnd: (v) {
            ref.read(audioHandlerProvider).seek(Duration(milliseconds: (v * 1000).round()));
            setState(() => _scrub = null);
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(formatTime(position), style: theme.textTheme.labelSmall),
              Text(duration > 0 ? '-${formatTime(duration - position)}' : '--:--', style: theme.textTheme.labelSmall),
            ],
          ),
        ),
      ],
    );
  }
}
