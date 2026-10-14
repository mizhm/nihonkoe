import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../state/player.dart';
import '../l10n.dart';

const speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

Future<void> showSpeedSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => Consumer(
        builder: (context, ref, _) {
          final rate = ref.watch(playerProvider).value?.rate ?? 1.0;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.l10n.speedTitle, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final speed in speeds)
                        ChoiceChip(
                          label: Text('$speed×'),
                          selected: speed == rate,
                          onSelected: (_) {
                            ref.read(audioHandlerProvider).setSpeed(speed);
                            Navigator.pop(context);
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
