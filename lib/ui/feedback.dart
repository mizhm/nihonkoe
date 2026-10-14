import 'package:material_ui/material_ui.dart';

import 'l10n.dart';

/// Runs a library write and tells the user if it failed (the UI otherwise shows nothing happened).
Future<void> reportErrors(BuildContext context, Future<void> action) async {
  final messenger = ScaffoldMessenger.of(context);
  final l = context.l10n;
  try {
    await action;
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(l.listErrorTitle)));
  }
}
