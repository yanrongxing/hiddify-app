import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/features/app_update/model/remote_version_entity.dart';
import 'package:hiddify/features/app_update/notifier/app_update_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gap/gap.dart';

class XlinkUpdateDialog extends HookConsumerWidget {
  const XlinkUpdateDialog({
    super.key,
    required this.remoteVersionEntity,
    required this.canIgnore,
  });

  final RemoteVersionEntity remoteVersionEntity;
  final bool canIgnore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isForceUpdate = remoteVersionEntity.isForceUpdate;
    final allowDismiss = !isForceUpdate;

    void onUpdateNow() async {
      final uri = Uri.parse(remoteVersionEntity.url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }

    void onMaybeLater() {
      if (!isForceUpdate) {
        ref.read(appUpdateNotifierProvider.notifier).ignoreRelease(remoteVersionEntity);
        context.pop();
      }
    }

    return PopScope(
      canPop: allowDismiss,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: 0.5),
                blurRadius: 30,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Stack(
            children: [
              // Background Gradients
              Positioned(
                top: -50,
                left: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        theme.colorScheme.primary.withValues(alpha: 0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -50,
                right: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        isDark ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.8) : theme.colorScheme.secondary.withValues(alpha: 0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top Bar (Close Button)
                    if (allowDismiss)
                      Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
                          onPressed: () => context.pop(),
                        ),
                      ),
                    if (!allowDismiss) const Gap(40),

                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: isDark ? theme.colorScheme.surfaceContainerHighest : theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(alpha: 0.15),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                        border: Border.all(color: isDark ? theme.colorScheme.outline.withValues(alpha: 0.3) : theme.colorScheme.primary.withValues(alpha: 0.2)),
                      ),
                      child: Icon(
                        Icons.system_update_rounded,
                        color: theme.colorScheme.primary,
                        size: 40,
                      ),
                    ),
                    const Gap(24),

                    Text(
                      t.dialogs.newVersion.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Gap(8),
                    Text(
                      remoteVersionEntity.updateContent.isNotEmpty
                          ? remoteVersionEntity.updateContent
                          : t.dialogs.newVersion.msg,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Gap(32),

                    // Actions
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onUpdateNow,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 8,
                          shadowColor: theme.colorScheme.primary.withValues(alpha: 0.25),
                        ),
                        child: Text(
                          t.dialogs.newVersion.updateNow,
                          style: const TextStyle(
                            fontFamily: 'Space Grotesk',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                    if (allowDismiss && canIgnore) ...[
                      const Gap(12),
                      TextButton(
                        onPressed: onMaybeLater,
                        child: Text(
                          t.common.close,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurfaceVariant,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
