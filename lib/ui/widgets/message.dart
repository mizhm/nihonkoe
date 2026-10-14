import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../l10n.dart';

class Message extends StatelessWidget {
  const Message({super.key, required this.icon, required this.title, this.hint, this.onRetry});
  final IconData icon;
  final String title;
  final String? hint;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(title, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
            if (hint != null) ...[
              const SizedBox(height: 4),
              Text(hint!, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonalIcon(onPressed: onRetry, icon: const Icon(Symbols.refresh), label: Text(context.l10n.commonRetry)),
            ],
          ],
        ),
      ),
    );
  }
}
