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
                      isAuth ? '您还没有订阅套餐' : '未登录或无订阅',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Gap(8),
                Text(
                  isAuth ? '购买套餐后即可使用高速节点' : '请先登录，然后购买订阅套餐',
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
                    child: Text(isAuth ? '立即购买' : '前往登录'),
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
    final plan = authUser?.planName ?? (subInfo != null ? '订阅套餐' : '暂无套餐');
    final daysLeft = subInfo != null && !subInfo.isExpired ? subInfo.remaining.inDays : 0;
    final usagePercent = subInfo != null ? subInfo.ratio : 0.0;

    final consumedStr = subInfo != null ? subInfo.consumption.sizeGB() : "0.0";
    final totalStr = subInfo != null ? subInfo.total.sizeGB() : "0.0";

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
                              "$daysLeft DAYS",
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
                        "Data Usage",
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
                              text: consumedStr.replaceAll(RegExp(r'[a-zA-Z\s]+'), ''),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              TextSpan(
                                text: " GiB",
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                              TextSpan(
                                text: " / ${totalStr.replaceAll(RegExp(r'[a-zA-Z\s]+'), '')}",
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                  fontSize: 14,
                                ),
                              ),
                              TextSpan(
                                text: " GiB",
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
                            title: const Text('需要登录'),
                            content: const Text('请先登录或注册后再更新订阅。'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('取消'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text('前往登录/注册'),
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
                            title: const Text('无可用订阅'),
                            content: const Text('您尚未订阅或订阅已过期，请前往购买订阅套餐。'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('取消'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text('前往订阅'),
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
