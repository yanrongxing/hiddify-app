import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/ticket/widget/in_app_browser_page.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SupportPage extends HookConsumerWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = ref.watch(translationsProvider).requireValue;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.pages.xlink.onlineSupport,
          style: theme.textTheme.titleMedium?.copyWith(
            fontFamily: 'Space Grotesk',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _SupportCard(
            icon: Icons.chat_bubble_outline_rounded,
            title: t.pages.xlink.liveSupport,
            subtitle: t.pages.xlink.liveSupportDesc,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => InAppBrowserPage(
                    url: 'https://tawk.to/chat/69e3f4246ef56e1c36f53d31/1jmh73cff',
                    title: t.pages.xlink.liveSupport,
                  ),
                ),
              );
            },
          ),
          const Gap(16),
          _SupportCard(
            icon: Icons.confirmation_number_outlined,
            title: t.pages.xlink.ticketCenter,
            subtitle: t.pages.xlink.ticketCenterDesc,
            onTap: () => context.pushNamed('ticketCenter'),
          ),
        ],
      ),
    );
  }
}

class _SupportCard extends StatelessWidget {
  const _SupportCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: theme.colorScheme.onPrimaryContainer, size: 28),
              ),
              const Gap(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const Gap(4),
                    Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
