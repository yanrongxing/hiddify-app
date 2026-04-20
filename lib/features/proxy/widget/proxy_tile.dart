import 'package:flutter/material.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/features/proxy/active/ip_widget.dart';
import 'package:hiddify/gen/fonts.gen.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:hiddify/utils/platform_utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ProxyTile extends HookConsumerWidget with PresLogger {
  const ProxyTile(this.proxy, {super.key, required this.selected, required this.onTap});

  final OutboundInfo proxy;
  final bool selected;
  final GestureTapCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final t = ref.watch(translationsProvider).requireValue;
    
    final isGroup = proxy.isGroup;
    final delayStr = proxy.urlTestDelay > 65000 ? "---" : "${proxy.urlTestDelay}ms";
    final isOffline = proxy.urlTestDelay > 65000 && proxy.urlTestDelay != 0;

    Color delayColorVal = delayColor(context, proxy.urlTestDelay);
    if (proxy.urlTestDelay == 0) delayColorVal = scheme.onSurfaceVariant; 

    return InkWell(
      onTap: onTap,
      onLongPress: () async => await ref.read(dialogNotifierProvider.notifier).showProxyInfo(outboundInfo: proxy),
      borderRadius: BorderRadius.circular(12),
      child: Opacity(
        opacity: isOffline ? 0.6 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? scheme.surfaceContainerHigh : scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? scheme.primary.withValues(alpha: 0.5) : scheme.outlineVariant.withValues(alpha: 0.15),
            ),
            boxShadow: selected
                ? [BoxShadow(color: scheme.primary.withValues(alpha: 0.06), blurRadius: 40)]
                : null,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (selected)
                Positioned(
                  left: -16,
                  top: -14,
                  bottom: -14,
                  width: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [scheme.primary, scheme.primaryContainer],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                    ),
                  ),
                ),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? null : scheme.surfaceContainerHighest,
                      gradient: selected
                          ? LinearGradient(
                              colors: [scheme.primary, scheme.primaryContainer],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      border: selected ? null : Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
                      boxShadow: selected
                          ? [BoxShadow(color: scheme.primary.withValues(alpha: 0.3), blurRadius: 15)]
                          : null,
                    ),
                    alignment: Alignment.center,
                    clipBehavior: Clip.antiAlias,
                    child: isGroup
                        ? Icon(
                            Icons.speed_rounded,
                            color: selected ? scheme.onPrimaryContainer : scheme.primary,
                            size: 20,
                          )
                        : IPCountryFlag(
                            countryCode: proxy.ipinfo.countryCode,
                            organization: proxy.ipinfo.org,
                            size: 40,
                          ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                proxy.tagDisplay,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: selected ? scheme.primary : scheme.onSurface,
                                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (selected) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: scheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: scheme.primary.withValues(alpha: 0.2)),
                                ),
                                child: Text(
                                  t.pages.xlink.active.toUpperCase(),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: scheme.primary,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              proxy.type.toLowerCase() == 'balancer' ? t.pages.xlink.balancer.toUpperCase() : proxy.type.toUpperCase(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                                fontSize: 10,
                              ),
                            ),
                            if (proxy.isGroup) ...[
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  "(${[
                                    'round-robin',
                                    'round robin'
                                  ].contains(proxy.groupSelectedTagDisplay.trim().toLowerCase()) ? t.pages.settings.routing.balancerStrategy.roundRobin : [
                                    'consistent-hash',
                                    'consistent hash'
                                  ].contains(proxy.groupSelectedTagDisplay.trim().toLowerCase()) ? t.pages.settings.routing.balancerStrategy.consistentHash : [
                                    'sticky-session',
                                    'sticky session'
                                  ].contains(proxy.groupSelectedTagDisplay.trim().toLowerCase()) ? t.pages.settings.routing.balancerStrategy.stickySession : proxy.groupSelectedTagDisplay.trim()})",
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    fontSize: 10,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ] else if (proxy.ipinfo.countryCode.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(width: 4, height: 4, decoration: BoxDecoration(color: scheme.outlineVariant, shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  proxy.ipinfo.org,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    fontSize: 10,
                                    fontFamily: 'Manrope',
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ]
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        delayStr,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isOffline ? scheme.onSurfaceVariant : delayColorVal,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Space Grotesk',
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected ? scheme.primary : Colors.transparent,
                          border: selected ? null : Border.all(color: scheme.outlineVariant),
                          boxShadow: selected
                              ? [BoxShadow(color: scheme.primary.withValues(alpha: 0.4), blurRadius: 10)]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: selected
                            ? Icon(Icons.check, size: 16, color: scheme.onPrimary)
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color delayColor(BuildContext context, int delay) {
    if (Theme.of(context).brightness == Brightness.dark) {
      return switch (delay) {
        < 800 => Colors.lightGreen,
        < 1500 => Colors.orange,
        _ => Colors.redAccent,
      };
    }
    return switch (delay) {
      < 800 => Colors.green,
      < 1500 => Colors.deepOrangeAccent,
      _ => Colors.red,
    };
  }
}
