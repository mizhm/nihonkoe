import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

import '../../state/player.dart';
import '../l10n.dart';
import '../links.dart';
import 'queue.dart';

Future<void> showMoreSheet(BuildContext context, {String base = ''}) => showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => Consumer(
        builder: (sheetContext, ref, _) {
          final l = sheetContext.l10n;
          final handler = ref.read(audioHandlerProvider);
          final snapshot = ref.watch(playerProvider).value;
          final item = snapshot?.current;
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(title: Text(l.playerMore, style: Theme.of(sheetContext).textTheme.titleMedium)),
                SwitchListTile(
                  secondary: const Icon(Symbols.shuffle),
                  title: Text(l.playerShuffle),
                  value: snapshot?.shuffle ?? false,
                  onChanged: (_) => handler.toggleShuffle(),
                ),
                if ((snapshot?.queue.length ?? 0) > 1)
                  ListTile(
                    leading: const Icon(Symbols.queue_music),
                    title: Text(l.playerQueue),
                    subtitle: Text(l.moreQueueCount(snapshot!.queue.length)),
                    trailing: const Icon(Symbols.chevron_right),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      showQueueSheet(context);
                    },
                  ),
                if (item != null)
                  ListTile(
                    leading: const Icon(Symbols.article),
                    title: Text(l.moreOpenWork),
                    trailing: const Icon(Symbols.chevron_right),
                    onTap: () {
                      final router = GoRouter.of(context);
                      Navigator.pop(sheetContext);
                      Navigator.pop(context); // close the player
                      router.push(postPath(base, item.post.id));
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
