import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../logic/chapters.dart';
import '../../logic/format.dart';
import '../../state/player.dart';
import '../l10n.dart';

Future<void> showChaptersSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const _ChaptersSheet(),
    );

class _ChaptersSheet extends ConsumerWidget {
  const _ChaptersSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(playerProvider).value?.current;
    if (item == null) return const SizedBox.shrink();
    final position = (ref.watch(positionProvider).value ?? Duration.zero).inMilliseconds / 1000;
    final active = chapterIndexAt(item.chapters, position);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (context, controller) => ListView(
        controller: controller,
        children: [
          ListTile(title: Text(context.l10n.playerChapters, style: Theme.of(context).textTheme.titleMedium)),
          for (final (i, chapter) in item.chapters.indexed)
            ListTile(
              selected: i == active,
              leading: Text(formatTime(chapter.startSeconds)),
              title: Text(chapter.title),
              onTap: () {
                ref.read(audioHandlerProvider).seek(Duration(seconds: chapter.startSeconds));
                Navigator.pop(context);
              },
            ),
        ],
      ),
    );
  }
}
