import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../api/client.dart';
import '../l10n.dart';
import '../screens/challenge.dart';

class Message extends StatelessWidget {
  const Message({super.key, required this.icon, required this.title, this.hint, this.onRetry, this.error});
  final IconData icon;
  final String title;
  final String? hint;
  final VoidCallback? onRetry;
  final Object? error; // a Cloudflare captcha adds a way to solve it

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final challenge = error is ChallengeException ? error as ChallengeException : null;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(title, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
            if (challenge != null || hint != null) ...[
              const SizedBox(height: 4),
              Text(challenge != null ? context.l10n.challengeHint : hint!, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonalIcon(onPressed: onRetry, icon: const Icon(Symbols.refresh), label: Text(context.l10n.commonRetry)),
            ],
            if (challenge != null) ...[
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () => ChallengeScreen.open(context, challenge.url).then((_) => onRetry?.call()),
                icon: const Icon(Symbols.public),
                label: Text(context.l10n.challengeOpen),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
