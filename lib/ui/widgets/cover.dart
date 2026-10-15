import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../state/core.dart';

class Cover extends ConsumerWidget {
  const Cover({super.key, this.url, this.aspectRatio, this.borderRadius = BorderRadius.zero, this.fit = BoxFit.cover});
  final String? url;
  final double? aspectRatio;
  final BorderRadius borderRadius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final placeholder = ColoredBox(
      color: colors.surfaceContainerHighest,
      child: Center(child: Icon(Symbols.headphones, color: colors.onSurfaceVariant)),
    );
    Widget image = url == null
        ? placeholder
        : Image(
            image: ref.watch(imageProviderFactory)(url!),
            fit: fit,
            filterQuality: FilterQuality.low,
            frameBuilder: (_, child, frame, sync) => sync || frame != null ? child : placeholder,
            errorBuilder: (_, _, _) => placeholder,
          );
    image = ClipRRect(borderRadius: borderRadius, child: SizedBox.expand(child: image));
    return aspectRatio == null ? image : AspectRatio(aspectRatio: aspectRatio!, child: image);
  }
}
