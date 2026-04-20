import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/auth/model/session_model.dart';
import 'package:hiddify/features/auth/notifier/session_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Modal bottom sheet shown when the user tries to connect but device limit is reached.
///
/// Displays active sessions (app and web) and allows removing them.
/// Returns `true` if the user clicks the "Connect" button (available after clearing enough devices).
class DeviceLimitDialog extends ConsumerStatefulWidget {
  const DeviceLimitDialog({
    super.key,
    required this.deviceLimit,
    required this.currentSessionId,
  });

  final int deviceLimit;
  final int? currentSessionId;

  /// Show the device limit dialog. Returns `true` if user wants to proceed with connection.
  static Future<bool?> show(
    BuildContext context, {
    required int deviceLimit,
    int? currentSessionId,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DeviceLimitDialog(
        deviceLimit: deviceLimit,
        currentSessionId: currentSessionId,
      ),
    );
  }

  @override
  ConsumerState<DeviceLimitDialog> createState() => _DeviceLimitDialogState();
}

class _DeviceLimitDialogState extends ConsumerState<DeviceLimitDialog> {
  int? _removingId;

  @override
  void initState() {
    super.initState();
    // Trigger initial fetch
    Future.microtask(() => ref.read(sessionNotifierProvider.notifier).refresh());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = ref.watch(translationsProvider).requireValue;
    final sessionsAsync = ref.watch(sessionNotifierProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Gap(16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Icon(
                  Icons.devices_other_rounded,
                  size: 48,
                  color: theme.colorScheme.error,
                ),
                const Gap(12),
                Text(
                  t.pages.xlink.deviceLimitReached,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Gap(8),
                Text(
                  t.pages.xlink.deviceLimitDialogHint,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const Gap(16),

          // Session list
          Flexible(
            child: sessionsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(32),
                child: Text('Error: $e'),
              ),
              data: (sessions) {
                final appSessions = sessions.where((s) => !s.isWeb).toList();
                final webSessions = sessions.where((s) => s.isWeb).toList();
                final currentCount = appSessions.length;
                final isOverLimit = currentCount >= widget.deviceLimit;

                return ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // Device count status
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isOverLimit
                            ? theme.colorScheme.errorContainer.withValues(alpha: 0.3)
                            : theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isOverLimit
                              ? theme.colorScheme.error.withValues(alpha: 0.3)
                              : theme.colorScheme.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isOverLimit ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                            color: isOverLimit ? theme.colorScheme.error : theme.colorScheme.primary,
                            size: 20,
                          ),
                          const Gap(8),
                          Text(
                            t.pages.xlink.deviceLimitInfo(
                              current: currentCount.toString(),
                              limit: widget.deviceLimit.toString(),
                            ),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isOverLimit ? theme.colorScheme.error : theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // App Devices Section
                    if (appSessions.isNotEmpty) ...[
                      _SectionHeader(title: t.pages.xlink.appDevices, theme: theme),
                      ...appSessions.map((session) => _SessionTile(
                            session: session,
                            isCurrentDevice: session.id == widget.currentSessionId,
                            isRemoving: _removingId == session.id,
                            onRemove: () => _confirmAndRemove(session),
                            t: t,
                          )),
                    ],

                    // Web Sessions Section
                    if (webSessions.isNotEmpty) ...[
                      const Gap(12),
                      _SectionHeader(title: t.pages.xlink.webSessions, theme: theme),
                      ...webSessions.map((session) => _SessionTile(
                            session: session,
                            isCurrentDevice: session.id == widget.currentSessionId,
                            isRemoving: _removingId == session.id,
                            onRemove: () => _confirmAndRemove(session),
                            t: t,
                          )),
                    ],
                  ],
                );
              },
            ),
          ),
          const Gap(16),

          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              children: [
                if (sessionsAsync.hasValue &&
                    sessionsAsync.value!.where((s) => !s.isWeb).length < widget.deviceLimit)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        t.pages.xlink.connect, // Use connect translation
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        MaterialLocalizations.of(context).cancelButtonLabel,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndRemove(SessionModel session) async {
    final t = ref.read(translationsProvider).requireValue;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.pages.xlink.removeDeviceConfirm),
        content: Text(t.pages.xlink.removeDeviceConfirmHint),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(t.pages.xlink.removeDevice),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _removeSession(session);
    }
  }

  Future<void> _removeSession(SessionModel session) async {
    final t = ref.read(translationsProvider).requireValue;

    setState(() => _removingId = session.id);
    final success = await ref.read(sessionNotifierProvider.notifier).removeSession(session.id);
    if (!mounted) return;
    setState(() => _removingId = null);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.pages.xlink.removeSuccess)),
      );
      // NOTE: We no longer auto-pop here. The user stays on the sheet to see the updated list.
      // If the count is now under the limit, the "Connect" button will appear.
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.pages.xlink.removeFailed)),
      );
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.theme});
  final String title;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({
    required this.session,
    required this.isCurrentDevice,
    required this.isRemoving,
    required this.onRemove,
    required this.t,
  });

  final SessionModel session;
  final bool isCurrentDevice;
  final bool isRemoving;
  final VoidCallback onRemove;
  final Translations t;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrentDevice
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.2)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: isCurrentDevice
            ? Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        children: [
          Icon(session.deviceIcon, size: 28, color: theme.colorScheme.primary),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      session.displayName,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (isCurrentDevice) ...[
                      const Gap(8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          t.pages.xlink.currentDevice,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (session.lastUsedAt != null) ...[
                  const Gap(4),
                  Text(
                    '${t.pages.xlink.lastActive}: ${_formatTime(session.lastUsedAt!)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!isCurrentDevice)
            isRemoving
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                : IconButton(
                    icon: Icon(Icons.remove_circle_outline_rounded, color: theme.colorScheme.error),
                    onPressed: onRemove,
                    tooltip: t.pages.xlink.removeDevice,
                  ),
        ],
      ),
    );
  }

  String _formatTime(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inHours < 1) return '${diff.inMinutes}m ago';
      if (diff.inDays < 1) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return dateStr;
    }
  }
}
