import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../logic/chapters.dart';
import '../../logic/sleep.dart';
import '../../state/player.dart';
import '../l10n.dart';
import '../sleep_text.dart';

Future<void> showSleepTimerSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const _SleepTimerSheet(),
    );

class _SleepTimerSheet extends ConsumerWidget {
  const _SleepTimerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final handler = ref.read(audioHandlerProvider);
    final snapshot = ref.watch(playerProvider).value;
    final item = snapshot?.current;
    final sleep = snapshot?.sleep ?? const SleepOff();
    final remaining = sleepRemaining(sleep, handler.now());
    final chapterEnd = item == null ? null : nextChapterStart(item.chapters, handler.position.inMilliseconds / 1000);

    void choose(SleepTimer timer) {
      handler.setSleep(timer);
      Navigator.pop(context);
    }

    Widget label(String text) => Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(text, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        );

    final minutes = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final m in sleepMinutes)
          ActionChip(label: Text(l.sleepMinutes(m)), onPressed: () => choose(SleepAt(handler.now() + m * 60000))),
      ],
    );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.sleepTitle, style: theme.textTheme.titleMedium),
            if (remaining != null) ...[
              Card.filled(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(sleepText(remaining, l), style: theme.textTheme.headlineMedium?.copyWith(color: theme.colorScheme.primary)),
                      if (sleep case SleepAt(:final deadline)) ...[
                        Text(l.sleepStopsAt(TimeOfDay.fromDateTime(DateTime.fromMillisecondsSinceEpoch(deadline)).format(context))),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final n in sleepExtend)
                              ActionChip(label: Text(l.sleepExtend(n)), onPressed: () => handler.extendSleepBy(n)),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      FilledButton.tonal(onPressed: () => choose(const SleepOff()), child: Text(l.sleepOff)),
                    ],
                  ),
                ),
              ),
              label(l.sleepChangeTo),
              minutes,
            ] else ...[
              label(l.sleepByMinutes),
              minutes,
              label(l.sleepByContent),
              if (item != null && chapterEnd != null)
                OutlinedButton(onPressed: () => choose(SleepAtPosition(item.key, chapterEnd)), child: Text(l.sleepChapterEnd)),
              OutlinedButton(onPressed: () => choose(const SleepItemEnd()), child: Text(l.sleepWorkEnd)),
            ],
          ],
        ),
      ),
    );
  }
}
