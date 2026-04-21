import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/auth/model/auth_state.dart';
import 'package:hiddify/features/auth/model/session_model.dart';
import 'package:hiddify/features/auth/notifier/auth_notifier.dart';
import 'package:hiddify/features/auth/notifier/session_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:flutter_hooks/flutter_hooks.dart';

/// Standalone page for managing active device sessions.
///
/// Shows all active sessions (app and web), allows removing non-current devices.
class DeviceManagePage extends HookConsumerWidget {
  const DeviceManagePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      Future.microtask(() {
        ref.read(sessionNotifierProvider.notifier).refresh();
        ref.read(authNotifierProvider.notifier).checkSubscriptionStatus(force: true);
      });
      return null;
    }, []);

    final theme = Theme.of(context);
    final t = ref.watch(translationsProvider).requireValue;
    final sessionsAsync = ref.watch(sessionNotifierProvider);
    final authState = ref.watch(authNotifierProvider);

    final deviceLimit = (authState is Authenticated) ? authState.user.deviceLimit : null;
    final currentSessionId = (authState is Authenticated)
        ? ref.read(authNotifierProvider.notifier).currentSessionId
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.pages.xlink.deviceManagement,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(sessionNotifierProvider.notifier).refresh();
          await ref.read(authNotifierProvider.notifier).checkSubscriptionStatus(force: true);
        },
        child: sessionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                const Gap(16),
                Text('Error: $e'),
                const Gap(16),
                FilledButton(
                  onPressed: () => ref.read(sessionNotifierProvider.notifier).refresh(),
                  child: Text(t.pages.xlink.retry),
                ),
              ],
            ),
          ),
          data: (sessions) {
            final appSessions = sessions.where((s) => !s.isWeb).toList();
            final webSessions = sessions.where((s) => s.isWeb).toList();

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(top: 16, bottom: 84),
              children: [
                // Status bar
                _StatusChip(
                  appCount: appSessions.length,
                  deviceLimit: deviceLimit,
                  theme: theme,
                  t: t,
                ),
                const Gap(20),

                // App Devices Section
                if (appSessions.isNotEmpty) ...[
                  _SectionHeader(
                    icon: Icons.devices_rounded,
                    title: t.pages.xlink.appDevices,
                    count: appSessions.length,
                    theme: theme,
                  ),
                  const Gap(8),
                  _SessionGroup(
                    sessions: appSessions,
                    currentSessionId: currentSessionId,
                    theme: theme,
                    t: t,
                    ref: ref,
                  ),
                  const Gap(20),
                ],

                // Web Sessions Section
                if (webSessions.isNotEmpty) ...[
                  _SectionHeader(
                    icon: Icons.language_rounded,
                    title: t.pages.xlink.webSessions,
                    count: webSessions.length,
                    theme: theme,
                  ),
                  const Gap(4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      t.pages.xlink.webSessionNote,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const Gap(8),
                  _SessionGroup(
                    sessions: webSessions,
                    currentSessionId: currentSessionId,
                    theme: theme,
                    t: t,
                    ref: ref,
                  ),
                ],

                if (sessions.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(48),
                      child: Column(
                        children: [
                          Icon(Icons.devices_rounded, size: 64, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
                          const Gap(16),
                          Text(
                            'No active sessions',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.appCount,
    required this.deviceLimit,
    required this.theme,
    required this.t,
  });

  final int appCount;
  final int? deviceLimit;
  final ThemeData theme;
  final Translations t;

  @override
  Widget build(BuildContext context) {
    final isOverLimit = deviceLimit != null && appCount >= deviceLimit!;
    final limitText = deviceLimit != null
        ? t.pages.xlink.deviceLimitInfo(
            current: appCount.toString(),
            limit: deviceLimit.toString(),
          )
        : '${t.pages.xlink.appDevices}: $appCount (${t.pages.xlink.noDeviceLimit})';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isOverLimit
            ? theme.colorScheme.errorContainer.withValues(alpha: 0.3)
            : theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
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
            size: 22,
          ),
          const Gap(10),
          Text(
            limitText,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isOverLimit ? theme.colorScheme.error : theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.count,
    required this.theme,
  });

  final IconData icon;
  final String title;
  final int count;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const Gap(8),
          Text(
            '$title ($count)',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionGroup extends StatelessWidget {
  const _SessionGroup({
    required this.sessions,
    required this.currentSessionId,
    required this.theme,
    required this.t,
    required this.ref,
  });

  final List<SessionModel> sessions;
  final int? currentSessionId;
  final ThemeData theme;
  final Translations t;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.15)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 30, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: sessions.asMap().entries.map((entry) {
          final index = entry.key;
          final session = entry.value;
          final isLast = index == sessions.length - 1;
          final isCurrent = session.id == currentSessionId;

          return _SessionItem(
            session: session,
            isCurrent: isCurrent,
            showBorder: !isLast,
            theme: theme,
            t: t,
            onRemove: isCurrent
                ? null
                : () async {
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
                      final success = await ref.read(sessionNotifierProvider.notifier).removeSession(session.id);
                      if (success) {
                        // Check subscription status to detect can_connect_vpn restoration
                        await ref.read(authNotifierProvider.notifier).checkSubscriptionStatus(force: true);
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success ? t.pages.xlink.removeSuccess : t.pages.xlink.removeFailed),
                          ),
                        );
                      }
                    }
                  },
          );
        }).toList(),
      ),
    );
  }
}

class _SessionItem extends StatelessWidget {
  const _SessionItem({
    required this.session,
    required this.isCurrent,
    required this.showBorder,
    required this.theme,
    required this.t,
    this.onRemove,
  });

  final SessionModel session;
  final bool isCurrent;
  final bool showBorder;
  final ThemeData theme;
  final Translations t;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: showBorder
            ? Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.1)))
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isCurrent
                  ? theme.colorScheme.primary.withValues(alpha: 0.15)
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(
              session.deviceIcon,
              size: 24,
              color: isCurrent ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        session.displayType,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    if (isCurrent) ...[
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
                    if (!session.isActive) ...[
                      const Gap(8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          t.pages.xlink.deviceOverLimit,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onError,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const Gap(4),

                if (session.deviceName != null && session.deviceName!.isNotEmpty && session.deviceName != 'localhost') ...[
                  Text(
                    t.pages.xlink.deviceNameLabel(name: session.deviceName!),
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const Gap(2),
                ],
                if (session.deviceId != null) ...[
                  Text(
                    t.pages.xlink.deviceIdLabel(id: session.deviceId!),
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(4),
                ],
                Row(
                  children: [
                    if (session.lastUsedAt != null) ...[
                      Icon(Icons.access_time, size: 12, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
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
              ],
            ),
          ),
          if (onRemove != null)
            IconButton(
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
