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
            color: const Color(0xFF131313), // background
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF3d4945).withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
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
                        const Color(0xFF69d9c0).withValues(alpha: 0.15),
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
                        const Color(0xFF1b1b1c).withValues(alpha: 0.8),
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
                          icon: const Icon(Icons.close, color: Color(0xFFbcc9c4)),
                          onPressed: () => context.pop(),
                        ),
                      ),
                    if (!allowDismiss) const Gap(40),

                    // Icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2a2a2a),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF69d9c0).withValues(alpha: 0.15),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                        border: Border.all(color: const Color(0xFF3d4945).withValues(alpha: 0.3)),
                      ),
                      child: const Icon(
                        Icons.system_update_rounded,
                        color: Color(0xFF69d9c0),
                        size: 40,
                      ),
                    ),
                    const Gap(24),

                    // Text
                    Text(
                      t.dialogs.newVersion.title,
                      style: const TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFe5e2e1),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Gap(8),
                    Text(
                      remoteVersionEntity.updateContent.isNotEmpty
                          ? remoteVersionEntity.updateContent
                          : t.dialogs.newVersion.msg,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: Color(0xFFbcc9c4),
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
                          backgroundColor: const Color(0xFF69d9c0),
                          foregroundColor: const Color(0xFF003027),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 8,
                          shadowColor: const Color(0xFF69d9c0).withValues(alpha: 0.25),
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
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFbcc9c4),
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
