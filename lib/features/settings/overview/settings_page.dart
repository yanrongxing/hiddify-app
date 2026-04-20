import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/preferences/feature_flags.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/core/router/go_router/helper/active_breakpoint_notifier.dart';
import 'package:hiddify/features/auth/model/auth_state.dart';
import 'package:hiddify/features/auth/notifier/auth_notifier.dart';
import 'package:hiddify/features/settings/notifier/config_option/config_option_notifier.dart';
import 'package:hiddify/features/settings/notifier/reset_tunnel/reset_tunnel_notifier.dart';
import 'package:hiddify/features/ticket/widget/in_app_browser_page.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hiddify/core/localization/locale_preferences.dart';
import 'package:hiddify/core/localization/locale_extensions.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

enum ConfigOptionSection {
  warp,
  fragment;

  static final _warpKey = GlobalKey(debugLabel: "warp-section-key");
  static final _fragmentKey = GlobalKey(debugLabel: "fragment-section-key");

  GlobalKey get key => switch (this) {
    ConfigOptionSection.warp => _warpKey,
    ConfigOptionSection.fragment => _fragmentKey,
  };
}

class SettingsPage extends HookConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);
    final authState = ref.watch(authNotifierProvider);

    final isAuthenticated = authState is Authenticated;
    final user = isAuthenticated ? authState.user : null;
    final email = user?.email ?? t.pages.xlink.guestUser;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.goNamed('home')),
        title: Text(t.pages.xlink.personalCenter, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.translate_rounded),
            onPressed: () async {
              final locale = ref.read(localePreferencesProvider);
              final selectedLocale = await ref
                  .read(dialogNotifierProvider.notifier)
                  .showSettingPicker<AppLocale>(
                    title: t.pages.settings.general.locale,
                    selected: locale,
                    onReset: () => ref.read(localePreferencesProvider.notifier).changeLocale(AppLocale.en),
                    options: [AppLocale.zhCn, AppLocale.en],
                    getTitle: (e) => e.localeName,
                  );
              if (selectedLocale != null) {
                await ref.read(localePreferencesProvider.notifier).changeLocale(selectedLocale);
              }
            },
          ),
          const Gap(8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(top: 16, bottom: 84),
        children: [
          // User Profile Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.surfaceContainerHighest,
                        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2), width: 2),
                        boxShadow: [BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.1), blurRadius: 20)],
                      ),
                      alignment: Alignment.center,
                      child: Icon(Icons.account_circle, size: 40, color: theme.colorScheme.primary),
                    ),
                    const Gap(16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            email,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontFamily: 'Space Grotesk',
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const Gap(4),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isAuthenticated ? theme.colorScheme.primary : theme.colorScheme.outline,
                                ),
                              ),
                              const Gap(8),
                              Text(
                                isAuthenticated
                                    ? (user?.planName ?? t.pages.xlink.freeUser)
                                    : t.pages.xlink.guest,
                                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Gap(24),
                if (!isAuthenticated)
                  FilledButton.icon(
                    onPressed: () => context.push('/login'),
                    icon: const Icon(Icons.login_rounded),
                    label: Text(t.pages.xlink.loginRegister),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 1.0,
                      ),
                    ),
                  )
                else ...[
                  if (user != null && user.planId != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(t.pages.xlink.mySubscription, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                              if (user.expiredAt != null)
                                Text(
                                  '${t.pages.xlink.expires}: ${DateTime.fromMillisecondsSinceEpoch(user.expiredAt! * 1000).toString().split(' ')[0]}',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                          const Gap(12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                t.pages.xlink.dataUsage,
                                style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              ),
                              Builder(
                                builder: (context) {
                                  String format(int bytes) {
                                    const gb = 1024 * 1024 * 1024;
                                    const mb = 1024 * 1024;
                                    if (bytes >= gb) {
                                      return '${(bytes / gb).toStringAsFixed(2)} GB';
                                    } else {
                                      return '${(bytes / mb).toStringAsFixed(1)} MB';
                                    }
                                  }

                                  return Text(
                                    '${format(user.u + user.d)} / ${format(user.transferEnable)}',
                                    style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                                  );
                                },
                              ),
                            ],
                          ),
                          const Gap(8),
                          LinearProgressIndicator(
                            value: user.transferEnable > 0 ? (user.u + user.d) / user.transferEnable : 0,
                            backgroundColor: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    ),
                    const Gap(16),
                  ],
                  Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.primaryContainer]),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          if (FeatureFlags.enableSubscriptionShop) {
                            context.pushNamed('shop');
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bolt_rounded, color: theme.colorScheme.onPrimaryContainer),
                              const Gap(8),
                              Text(
                                user?.planId != null ? t.pages.xlink.renewUpgrade : t.pages.xlink.subscribeNow,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                  fontFamily: 'Space Grotesk',
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Gap(24),

          // Group 1: Utilities
          _MenuGroup(
            children: [
              if (FeatureFlags.enableSubscriptionShop)
                _MenuItem(icon: Icons.storefront_rounded, title: t.pages.xlink.subscriptionShop, onTap: () => context.pushNamed('shop')),
              _MenuItem(icon: Icons.qr_code_scanner_rounded, title: '掃描二維碼', onTap: () {}),
              _MenuItem(
                icon: Icons.share_rounded,
                title: t.pages.share.title,
                onTap: () {
                  if (ref.read(authNotifierProvider) is Authenticated) {
                    context.pushNamed('share');
                  } else {
                    context.push('/login');
                  }
                },
              ),
              _MenuItem(icon: Icons.local_activity_rounded, title: t.pages.xlink.coupons, onTap: () {}, showBorder: false),
            ],
          ),
          const Gap(16),

          // Group 2: Support & Info
          _MenuGroup(
            children: [
              _MenuItem(
                icon: Icons.layers_rounded,
                title: t.pages.settings.general.title,
                onTap: () => context.go(context.namedLocation('general')),
              ),
              _MenuItem(
                icon: Icons.settings_rounded,
                title: t.pages.xlink.advancedSettings,
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AdvancedSettingsPage()));
                },
              ),
              _MenuItem(
                icon: Icons.help_outline_rounded,
                title: t.pages.xlink.helpCenter,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => InAppBrowserPage(url: 'https://47.79.38.161/#/tutorial', title: t.pages.xlink.helpCenter),
                    ),
                  );
                },
              ),
              _MenuItem(
                icon: Icons.support_agent_rounded,
                title: t.pages.xlink.onlineSupport,
                onTap: () => context.go(context.namedLocation('support')),
              ),
              _MenuItem(icon: Icons.alternate_email_rounded, title: t.pages.xlink.officialXAccount, onTap: () {}),
              _MenuItem(
                icon: Icons.info_outline_rounded,
                title: t.pages.xlink.aboutApp,
                onTap: () => context.go(context.namedLocation('about')),
                showBorder: false,
              ),
            ],
          ),
          const Gap(24),

          // Group 3: Logout
          if (isAuthenticated)
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.15)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 30, offset: const Offset(0, 8)),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    await ref.read(authNotifierProvider.notifier).logout();
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        '退出登錄',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.error,
                          fontFamily: 'Space Grotesk',
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MenuGroup extends StatelessWidget {
  const _MenuGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.15)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 30, offset: const Offset(0, 8))],
      ),
      child: Column(children: children),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.icon, required this.title, required this.onTap, this.showBorder = true, this.color});

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool showBorder;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: showBorder
                ? Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.1)))
                : null,
          ),
          child: Row(
            children: [
              Icon(icon, color: color ?? theme.colorScheme.primary, size: 24),
              const Gap(12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(color: color ?? theme.colorScheme.onSurface),
                ),
              ),
              if (color == null)
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class AdvancedSettingsPage extends HookConsumerWidget {
  const AdvancedSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.pages.settings.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontFamily: 'Space Grotesk',
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // Configuration Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Text(
              'CONFIGURATION',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 2.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Configuration Group
          _MenuGroup(
            children: [
              if (!FeatureFlags.hideAdvancedSettings) ...[
                _MenuItem(
                  icon: Icons.data_usage_rounded,
                  title: '流量记录 (Traffic Records)',
                  onTap: () => context.go(context.namedLocation('trafficRecords')),
                ),
                _MenuItem(
                  icon: Icons.route_rounded,
                  title: t.pages.settings.routing.title,
                  onTap: () => context.go(context.namedLocation('routeOptions')),
                ),
                _MenuItem(
                  icon: Icons.dns_rounded,
                  title: t.pages.settings.dns.title,
                  onTap: () => context.go(context.namedLocation('dnsOptions')),
                ),
                _MenuItem(
                  icon: Icons.input_rounded,
                  title: t.pages.settings.inbound.title,
                  onTap: () => context.go(context.namedLocation('inboundOptions')),
                ),
                _MenuItem(
                  icon: Icons.content_cut_rounded,
                  title: t.pages.settings.tlsTricks.title,
                  onTap: () => context.go(context.namedLocation('tlsTricks')),
                ),
                _MenuItem(
                  icon: Icons.cloud_rounded,
                  title: t.pages.settings.warp.title,
                  onTap: () => context.go(context.namedLocation('warpOptions')),
                  showBorder: false,
                ),
              ],
            ],
          ),
          const Gap(24),

          // System Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Text(
              'SYSTEM',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 2.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // System Group
          _MenuGroup(
            children: [
              if (Breakpoint(context).isMobile()) ...[
                _MenuItem(
                  icon: Icons.receipt_long_rounded,
                  title: t.pages.logs.title,
                  onTap: () => context.go(context.namedLocation('logs')),
                ),
              ],
              _MenuItem(
                icon: Icons.warning_amber_rounded,
                title: t.pages.settings.resetTunnel,
                onTap: () async {
                  await ref.read(configOptionNotifierProvider.notifier).resetOption();
                },
                showBorder: false,
                color: theme.colorScheme.error,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SettingsSection extends HookConsumerWidget {
  const SettingsSection({super.key, required this.title, required this.icon, required this.routeName});

  final String title;
  final IconData icon;
  final String routeName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => context.go(context.namedLocation(routeName)),
    );
  }
}
