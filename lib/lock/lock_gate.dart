import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

import '../state/settings.dart';
import '../ui/l10n.dart';
import 'authenticator.dart';

/// Covers the whole app (player included) until the user authenticates, on start and after backgrounding.
class LockGate extends ConsumerStatefulWidget {
  const LockGate({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<LockGate> createState() => _LockGateState();
}

class _LockGateState extends ConsumerState<LockGate> with WidgetsBindingObserver {
  late bool _locked = ref.read(settingsProvider).appLock;
  bool _authenticating = false;
  bool _promptOnResume = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_locked) WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The PIN/pattern fallback is a separate Android activity: the app "backgrounds" while any prompt is open.
    final busy = ref.read(authInProgressProvider).value;
    if (state == AppLifecycleState.paused) {
      // The system may cancel our own prompt in the background; ask again on return unless it succeeds first.
      if (_authenticating) _promptOnResume = true;
      if (!busy && ref.read(settingsProvider).appLock) {
        setState(() => _locked = true);
        _promptOnResume = true;
      }
    }
    if (state == AppLifecycleState.resumed && _promptOnResume && !busy) {
      _promptOnResume = false;
      _unlock();
    }
  }

  Future<void> _unlock() async {
    if (_authenticating || !mounted) return;
    final l = context.l10n;
    _authenticating = true;
    final result = await runAuthentication(ref, l.lockPrompt).whenComplete(() => _authenticating = false);
    if (!mounted) return;
    // No screen lock on the phone any more: nothing to authenticate with, and anyone holding it has access anyway.
    // Unlock and turn app lock off rather than lock the user out for good.
    if (result == AuthResult.unavailable) ref.read(settingsProvider.notifier).setAppLock(false);
    setState(() {
      if (result == AuthResult.success || result == AuthResult.unavailable) {
        _locked = false;
        _promptOnResume = false;
      }
      _message = result == AuthResult.lockout ? l.lockLockout : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    return Stack(
      children: [
        // While locked, screen readers and keyboard focus must not reach the app underneath.
        ExcludeSemantics(excluding: _locked, child: ExcludeFocus(excluding: _locked, child: widget.child)),
        if (_locked)
          Positioned.fill(
            child: Material(
              color: theme.colorScheme.surface,
              child: SafeArea(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Symbols.lock, size: 48, color: theme.colorScheme.primary),
                      const SizedBox(height: 12),
                      Text('nihonkoe', style: theme.textTheme.titleLarge),
                      if (_message != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(32, 12, 32, 0),
                          child: Text(_message!, textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.error)),
                        ),
                      const SizedBox(height: 16),
                      FilledButton.icon(onPressed: _unlock, icon: const Icon(Symbols.fingerprint), label: Text(l.lockUnlock)),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Turning the lock on or off needs a successful authentication; on needs a device screen lock.
Future<void> setAppLockSecurely(BuildContext context, WidgetRef ref, bool enabled) async {
  final l = context.l10n;
  final auth = ref.read(authenticatorProvider);
  Future<void> tell(String title, String body) => showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(MaterialLocalizations.of(context).okButtonLabel))],
        ),
      );
  if (enabled && !await auth.isAvailable()) {
    if (context.mounted) await tell(l.lockUnavailableTitle, l.lockUnavailable);
    return;
  }
  final result = await runAuthentication(ref, enabled ? l.lockEnablePrompt : l.lockDisablePrompt);
  if (result == AuthResult.success) {
    ref.read(settingsProvider.notifier).setAppLock(enabled);
  } else if (result == AuthResult.unavailable && context.mounted) {
    await tell(l.lockUnavailableTitle, l.lockUnavailable);
  } else if (result == AuthResult.lockout && context.mounted) {
    await tell(l.lockFailedTitle, l.lockLockout);
  }
}
