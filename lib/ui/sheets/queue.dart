import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

import '../../state/player.dart';
import '../l10n.dart';
import '../widgets/cover.dart';

Future<void> showQueueSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const _QueueSheet(),
    );

class _QueueSheet extends ConsumerWidget {
  const _QueueSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final handler = ref.read(audioHandlerProvider);
    final snapshot = ref.watch(playerProvider).value;
    if (snapshot == null) return const SizedBox.shrink();
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (context, controller) => Column(
        children: [
          ListTile(
            title: Text(l.playerQueue, style: Theme.of(context).textTheme.titleMedium),
            trailing: IconButton(
              tooltip: snapshot.shuffle ? l.playerShuffleOff : l.playerShuffle,
              isSelected: snapshot.shuffle,
              icon: const Icon(Symbols.shuffle),
              onPressed: handler.toggleShuffle,
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              scrollController: controller,
              itemCount: snapshot.queue.length,
              // onReorderItem already gives the final index (Flutter adjusts for the removed item).
              onReorderItem: handler.moveItem,
              itemBuilder: (context, i) {
                final entry = snapshot.queue[i];
                final current = i == snapshot.index;
                final tile = ListTile(
                  key: ValueKey(entry.key),
                  selected: current,
                  leading: SizedBox.square(dimension: 40, child: Cover(url: entry.post.cover, borderRadius: BorderRadius.circular(8))),
                  title: Text(entry.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: entry.post.cv == null ? null : Text(entry.post.cv!, maxLines: 1),
                  onTap: () => handler.jumpTo(i),
                  // The playing item cannot be removed.
                  trailing: current
                      ? null
                      : IconButton(
                          tooltip: l.queueRemove(entry.title),
                          icon: const Icon(Symbols.close),
                          onPressed: () => handler.removeKey(entry.key),
                        ),
                );
                return current
                    ? tile
                    : Dismissible(
                        key: ValueKey('dismiss-${entry.key}'),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => handler.removeKey(entry.key),
                        child: tile,
                      );
              },
            ),
          ),
        ],
      ),
    );
  }
}
