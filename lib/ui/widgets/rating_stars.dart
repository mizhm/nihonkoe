import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n.dart';

class RatingStars extends StatelessWidget {
  const RatingStars({super.key, required this.value, required this.onChanged});
  final int value; // 0 = unrated
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var star = 1; star <= 5; star++)
          IconButton(
            tooltip: l.detailRate(star),
            isSelected: star <= value,
            icon: Icon(Symbols.star, fill: star <= value ? 1 : 0, color: star <= value ? colors.tertiary : colors.onSurfaceVariant),
            // Tapping the current rating clears it.
            onPressed: () => onChanged(star == value ? 0 : star),
          ),
      ],
    );
  }
}
