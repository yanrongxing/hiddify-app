import 'dart:math' as math;
import 'dart:ui';
import 'package:go_router/go_router.dart';
import 'package:dartx/dartx.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/app_info/app_info_provider.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/preferences/feature_flags.dart';
import 'package:hiddify/core/router/bottom_sheets/bottom_sheets_notifier.dart';
import 'package:hiddify/core/router/go_router/helper/active_breakpoint_notifier.dart';
import 'package:hiddify/features/home/widget/connection_button.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/profile/notifier/profile_notifier.dart';
import 'package:hiddify/features/profile/widget/profile_tile.dart';
import 'package:hiddify/features/proxy/active/active_proxy_card.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/proxy/active/active_proxy_delay_indicator.dart';
import 'package:hiddify/gen/assets.gen.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hiddify/features/auth/model/auth_state.dart';
import 'package:hiddify/features/auth/notifier/auth_notifier.dart';

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = ref.watch(translationsProvider).requireValue;
    // final hasAnyProfile = ref.watch(hasAnyProfileProvider);
    final activeProfile = ref.watch(activeProfileProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        toolbarHeight: 50,
        backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.6),
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFF3D4945).withValues(alpha: 0.15), height: 1.0),
        ),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(color: Colors.transparent),
          ),
        ),
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Assets.images.logo.svg(),
        ),
        title: const Text(
          "XLINK VPN",
          style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.w900, fontFamily: 'Space Grotesk'),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.account_circle, color: theme.colorScheme.onSurface, size: 28),
            onPressed: () => context.push('/settings'),
          ),
          const Gap(8),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: Container(
                height: math.max(constraints.maxHeight, 620),
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.7,
                    colors: [theme.colorScheme.primary.withValues(alpha: 0.15), theme.colorScheme.surface],
                    stops: const [0.0, 0.7],
                  ),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 448),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: HomeDataCard(
                              profile: activeProfile.valueOrNull,
                            ),
                          ),
                          const ConnectionButton(),
                          const Positioned(bottom: 0, left: 0, right: 0, child: ActiveProxyFooter()),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class AppVersionLabel extends HookConsumerWidget {
  const AppVersionLabel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);

    final version = ref.watch(appInfoProvider).requireValue.presentVersion;
    if (version.isBlank) return const SizedBox();

    return Semantics(
      label: t.common.version,
      button: false,
      child: Container(
        decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(4)),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        child: Text(
          version,
          textDirection: TextDirection.ltr,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onPrimaryContainer),
        ),
      ),
    );
  }
}

class HomeDataCard extends HookConsumerWidget {
  const HomeDataCard({super.key, this.profile});

  final ProfileEntity? profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = ref.watch(translationsProvider).requireValue;
    final isAuth = ref.watch(authNotifierProvider) is Authenticated;
    
    if (profile == null) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF353535).withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.15)),
        ),
        clipBehavior: Clip.antiAlias,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.bolt_rounded, color: theme.colorScheme.primary),
                    const Gap(8),
                    Text(
                      isAuth ? t.pages.xlink.noSubscription : t.pages.xlink.notLoggedIn,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Gap(8),
                Text(
                  isAuth ? t.pages.xlink.noSubscriptionHint : t.pages.xlink.notLoggedInHint,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const Gap(16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      if (isAuth) {
                        if (FeatureFlags.enableSubscriptionShop) {
                          context.pushNamed('shop');
                        } else {
                          UriUtils.tryLaunch(Uri.parse('https://47.79.38.161/#/plan'));
                        }
                      } else {
                        context.pushNamed('login');
                      }
                    },
                    child: Text(isAuth ? t.pages.xlink.buyNow : t.pages.xlink.goLogin),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final subInfo = profile is RemoteProfileEntity ? (profile as RemoteProfileEntity).subInfo : null;
    final authState = ref.watch(authNotifierProvider);
    final authUser = authState is Authenticated ? authState.user : null;

    // Plan name: prefer auth user's plan name (from API), fallback to profile sub info
    final plan = authUser?.planName ?? (subInfo != null ? t.pages.xlink.subscriptionShop : t.pages.xlink.noSubscription);
    final daysLeft = authUser?.expiredAt != null
        ? (DateTime.fromMillisecondsSinceEpoch(authUser!.expiredAt! * 1000).difference(DateTime.now()).inDays).clamp(0, 9999)
        : (subInfo != null && !subInfo.isExpired ? subInfo.remaining.inDays : 0);

    final bool hasApiTraffic = authUser != null && authUser.transferEnable > 0;
    final int usedBytes = hasApiTraffic ? (authUser!.u + authUser.d) : 0;
    final int totalBytes = hasApiTraffic ? authUser!.transferEnable : 0;
    final double usagePercent = totalBytes > 0
        ? (usedBytes / totalBytes).clamp(0.0, 1.0)
        : (subInfo?.ratio ?? 0.0);
    // Smart formatter: < 1 GB → show in MB, otherwise GB
    (String value, String unit) formatBytes(int bytes) {
      const gb = 1024 * 1024 * 1024;
      const mb = 1024 * 1024;
      if (bytes >= gb) {
        return ((bytes / gb).toStringAsFixed(2), 'GB');
      } else {
        return ((bytes / mb).toStringAsFixed(1), 'MB');
      }
    }
    final (consumedVal, consumedUnit) = hasApiTraffic
        ? formatBytes(usedBytes)
        : (subInfo?.consumption.sizeGB() ?? '0.0', 'GB');
    final (totalVal, totalUnit) = hasApiTraffic
        ? formatBytes(totalBytes)
        : (subInfo?.total.sizeGB() ?? '0.0', 'GB');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF353535).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.15)),
      ),
      clipBehavior: Clip.antiAlias,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20).copyWith(top: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          plan.toUpperCase(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Space Grotesk',
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.colorScheme.primary,
                                boxShadow: [
                                  BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.5), blurRadius: 8),
                                ],
                              ),
                            ),
                            const Gap(8),
                            Text(
                              "$daysLeft ${t.pages.xlink.days}",
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurface,
                                letterSpacing: 1.5,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Gap(16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        t.pages.xlink.dataUsage,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 14,
                          fontFamily: 'Inter',
                        ),
                      ),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: consumedVal,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            TextSpan(
                              text: " $consumedUnit",
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                            TextSpan(
                              text: " / $totalVal",
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontSize: 14,
                              ),
                            ),
                            TextSpan(
                              text: " $totalUnit",
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ],
                    ),
                    const Gap(8),
                    Container(
                      height: 8,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: usagePercent,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF69d9c0), Color(0xFF26a28b)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: const BorderRadius.only(bottomRight: Radius.circular(12)),
                ),
                child: IconButton(
                  icon: const Icon(Icons.sync_rounded, size: 18),
                  visualDensity: VisualDensity.compact,
                  color: theme.colorScheme.primary,
                  onPressed: () async {
                    final isAuthenticated = ref.read(authNotifierProvider) is Authenticated;
                    if (!isAuthenticated) {
                      final shouldLogin = await showDialog<bool>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text(t.pages.xlink.needLogin),
                            content: Text(t.pages.xlink.needLoginHint),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: Text(t.common.cancel),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: Text(t.pages.xlink.goLogin),
                              ),
                            ],
                          );
                        },
                      );
                      if (shouldLogin == true && context.mounted) {
                        context.pushNamed('login');
                      }
                      return;
                    }
                    final p = profile;
                    if (p == null) {
                      final shouldSubscribe = await showDialog<bool>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text(t.pages.xlink.noActiveSubscription),
                            content: Text(t.pages.xlink.noActiveSubscriptionHint),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: Text(t.common.cancel),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: Text(t.pages.xlink.goSubscribe),
                              ),
                            ],
                          );
                        },
                      );
                      if (shouldSubscribe == true && context.mounted) {
                        if (FeatureFlags.enableSubscriptionShop) {
                          context.pushNamed('shop');
                        } else {
                          UriUtils.tryLaunch(Uri.parse('https://47.79.38.161/#/plan'));
                        }
                      }
                      return;
                    }
                    
                    if (p is RemoteProfileEntity) {
                      ref.read(updateProfileNotifierProvider(p.id).notifier).updateProfile(p);
                    }
                    ref.read(authNotifierProvider.notifier).syncSubscription();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
