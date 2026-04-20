import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/auth/model/auth_state.dart';
import 'package:hiddify/features/auth/notifier/auth_notifier.dart';
import 'package:hiddify/features/share/model/invite_data.dart';
import 'package:hiddify/features/share/notifier/share_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:share_plus/share_plus.dart';

class SharePage extends HookConsumerWidget {
  const SharePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = ref.watch(translationsProvider).requireValue;
    final authState = ref.watch(authNotifierProvider);

    // Unauthenticated state
    if (authState is! Authenticated) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            t.pages.share.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontFamily: 'Space Grotesk',
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 64,
                    color: theme.colorScheme.outline),
                const Gap(16),
                Text(
                  t.pages.share.loginRequired,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Gap(24),
                FilledButton(
                  onPressed: () => context.push('/login'),
                  child: Text(t.pages.share.loginButton),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final shareAsync = ref.watch(shareNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.pages.share.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontFamily: 'Space Grotesk',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: shareAsync.when(
        loading: () => _buildShimmer(theme),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 64,
                  color: theme.colorScheme.error),
              const Gap(16),
              Text(
                '$err',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const Gap(24),
              FilledButton(
                onPressed: () => ref.invalidate(shareNotifierProvider),
                child: Text(t.pages.share.errorRetry),
              ),
            ],
          ),
        ),
        data: (data) => ListView(
          padding: const EdgeInsets.all(16).copyWith(bottom: 84),
          children: [
            _CommissionCard(data: data, t: t),
            const Gap(24),
            _InviteCodesSection(data: data, t: t),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const Gap(24),
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const Gap(12),
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Commission overview card
// ---------------------------------------------------------------------------

class _CommissionCard extends StatelessWidget {
  const _CommissionCard({required this.data, required this.t});
  final InviteData data;
  final Translations t;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final stats = <_StatItem>[
      _StatItem(t.pages.share.inviteCount, '${data.inviteCount}'),
      if (data.isDistributionEnabled) ...[
        _StatItem(t.pages.share.commissionRateL1,
            '${data.commissionRateL1}%'),
        _StatItem(t.pages.share.commissionRateL2,
            '${data.commissionRateL2}%'),
        _StatItem(t.pages.share.commissionRateL3,
            '${data.commissionRateL3}%'),
      ] else
        _StatItem(t.pages.share.commissionRate,
            '${data.commissionRateL1}%'),
      _StatItem(t.pages.share.pendingCommission,
          data.formatAmount(data.pendingAmount)),
      _StatItem(t.pages.share.totalCommission,
          data.formatAmount(data.totalCommission)),
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.pages.share.commissionBalance,
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.5,
              color: theme.colorScheme.primary,
            ),
          ),
          const Gap(8),
          Text(
            data.formatAmount(data.commissionBalance),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontFamily: 'Space Grotesk',
              fontWeight: FontWeight.bold,
            ),
          ),
          const Gap(20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: stats
                .map((s) => _StatChip(label: s.label, value: s.value))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _StatItem {
  const _StatItem(this.label, this.value);
  final String label;
  final String value;
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
          const Gap(4),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Invite codes section
// ---------------------------------------------------------------------------

class _InviteCodesSection extends HookConsumerWidget {
  const _InviteCodesSection({required this.data, required this.t});
  final InviteData data;
  final Translations t;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLoading = ref.watch(shareNotifierProvider).isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              t.pages.share.inviteLinks,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: isLoading
                  ? null
                  : () => ref
                      .read(shareNotifierProvider.notifier)
                      .generateCode(),
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_circle_outline, size: 18),
              label: Text(t.pages.share.generateCode),
            ),
          ],
        ),
        const Gap(16),
        if (data.codes.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.link_off, size: 48,
                    color: theme.colorScheme.outline),
                const Gap(12),
                Text(
                  t.pages.share.noCodesYet,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          )
        else
          ...data.codes.map(
            (code) => _InviteCodeCard(code: code, data: data, t: t),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Individual invite code card
// ---------------------------------------------------------------------------

class _InviteCodeCard extends StatelessWidget {
  const _InviteCodeCard({
    required this.code,
    required this.data,
    required this.t,
  });
  final String code;
  final InviteData data;
  final Translations t;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = data.inviteUrl(code);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Code badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              code,
              style: theme.textTheme.labelLarge?.copyWith(
                fontFamily: 'monospace',
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Gap(12),
          // URL display
          TextField(
            controller: TextEditingController(text: url),
            readOnly: true,
            style: theme.textTheme.bodySmall,
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerLowest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
          const Gap(12),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: url));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(t.pages.share.copied),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  icon: const Icon(Icons.content_copy, size: 16),
                  label: Text(t.pages.share.copyLink),
                ),
              ),
              const Gap(8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => SharePlus.instance.share(
                    ShareParams(text: url),
                  ),
                  icon: const Icon(Icons.share, size: 16),
                  label: Text(t.pages.share.shareLink),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
