import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/widget/shimmer_skeleton.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ActiveProxyDelayIndicator extends HookConsumerWidget with InfraLogger {
  const ActiveProxyDelayIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final activeProxy = ref.watch(activeProxyNotifierProvider);
    final theme = Theme.of(context);

    if (activeProxy is! AsyncData) {
      return const SizedBox(); // Avoid building widget if data is not available
    }

    final proxy = activeProxy.value!;
    final delay = proxy.urlTestDelay;
    final timeout = delay > 65000;

    return Center(
      child: InkWell(
        onTap: () async {
          try {
            await ref.read(activeProxyNotifierProvider.notifier).urlTest("");
          } catch (e) {
            // Handle error here
            loggy.error("Error during URL test: $e");
          }
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.speed_rounded, size: 14, color: theme.colorScheme.primary),
              const Gap(8),
              if (delay > 0)
                Text.rich(
                  semanticsLabel: timeout ? t.pages.proxies.delay.timeout : t.pages.proxies.delay.result(delay: delay),
                  TextSpan(
                    children: [
                      if (timeout)
                        TextSpan(
                          text: t.common.timeout,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.error,
                            letterSpacing: 1.5,
                            fontFamily: 'Manrope',
                          ),
                        )
                      else ...[
                        TextSpan(
                          text: "$delay ms ping",
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface,
                            letterSpacing: 1.5,
                            fontFamily: 'Manrope',
                          ),
                        ),
                      ],
                    ],
                  ),
                )
              else
                Semantics(label: t.pages.proxies.delay.testing, child: const ShimmerSkeleton(width: 48, height: 18)),
            ],
          ),
        ),
      ),
    );
  }
}
