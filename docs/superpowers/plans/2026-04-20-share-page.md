# Share Page Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a lightweight invite/share page in the Hiddify Flutter app that shows commission stats, invite codes, and enables link sharing via clipboard and system share.

**Architecture:** New `share` feature module (repository → notifier → widget) following the existing `traffic` feature pattern. Reuses `AuthRepository.dio` for API calls. Three-level commission distribution supported.

**Tech Stack:** Flutter, Riverpod (code-gen), Freezed, Dio, share_plus, slang i18n

**Spec:** `docs/superpowers/specs/2026-04-20-share-page-design.md`

---

### Task 1: Add i18n Keys

**Files:**
- Modify: `assets/translations/en.i18n.json`
- Modify: `assets/translations/zh-CN.i18n.json`
- Modify: `assets/translations/zh-TW.i18n.json`

- [ ] **Step 1:** Add `share` namespace inside `pages` in `en.i18n.json`:

```json
"share": {
  "title": "Invite & Earn",
  "commissionBalance": "Commission Balance",
  "inviteCount": "Invitees",
  "commissionRate": "Commission Rate",
  "commissionRateL1": "L1 Rate",
  "commissionRateL2": "L2 Rate",
  "commissionRateL3": "L3 Rate",
  "pendingCommission": "Pending",
  "totalCommission": "Total Earned",
  "inviteLinks": "Invite Links",
  "generateCode": "Generate Code",
  "generating": "Generating...",
  "noCodesYet": "No invite codes yet. Tap generate to create one.",
  "copyLink": "Copy Link",
  "copied": "Copied!",
  "shareLink": "Share",
  "shareMessage": "Join me on XLINK VPN! Sign up here: ${url}",
  "loginRequired": "Please log in to use the invite feature.",
  "loginButton": "Log In",
  "errorRetry": "Retry"
}
```

- [ ] **Step 2:** Add equivalent `share` namespace in `zh-CN.i18n.json`:

```json
"share": {
  "title": "邀请返现",
  "commissionBalance": "可用余额",
  "inviteCount": "邀请人数",
  "commissionRate": "返利比例",
  "commissionRateL1": "L1 比例",
  "commissionRateL2": "L2 比例",
  "commissionRateL3": "L3 比例",
  "pendingCommission": "待确认佣金",
  "totalCommission": "累计佣金",
  "inviteLinks": "邀请链接",
  "generateCode": "生成邀请码",
  "generating": "生成中...",
  "noCodesYet": "暂无邀请码，点击生成按钮创建。",
  "copyLink": "复制链接",
  "copied": "已复制！",
  "shareLink": "分享",
  "shareMessage": "加入 XLINK VPN，注册链接：${url}",
  "loginRequired": "请先登录以使用邀请功能。",
  "loginButton": "前往登录",
  "errorRetry": "重试"
}
```

- [ ] **Step 3:** Add equivalent `share` namespace in `zh-TW.i18n.json`:

```json
"share": {
  "title": "邀請返現",
  "commissionBalance": "可用餘額",
  "inviteCount": "邀請人數",
  "commissionRate": "返利比例",
  "commissionRateL1": "L1 比例",
  "commissionRateL2": "L2 比例",
  "commissionRateL3": "L3 比例",
  "pendingCommission": "待確認佣金",
  "totalCommission": "累計佣金",
  "inviteLinks": "邀請連結",
  "generateCode": "生成邀請碼",
  "generating": "生成中...",
  "noCodesYet": "暫無邀請碼，點擊生成按鈕建立。",
  "copyLink": "複製連結",
  "copied": "已複製！",
  "shareLink": "分享",
  "shareMessage": "加入 XLINK VPN，註冊連結：${url}",
  "loginRequired": "請先登入以使用邀請功能。",
  "loginButton": "前往登入",
  "errorRetry": "重試"
}
```

- [ ] **Step 4:** Run `dart run slang` to regenerate translation code.

- [ ] **Step 5:** Commit: `git add .; git commit -m "i18n: add share page translation keys"`

---

### Task 2: Create Data Layer

**Files:**
- Create: `lib/features/share/data/share_repository.dart`
- Create: `lib/features/share/data/share_data_providers.dart`

- [ ] **Step 1:** Create `lib/features/share/data/share_repository.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:hiddify/utils/custom_loggers.dart';

class ShareRepository with InfraLogger {
  ShareRepository({required Dio dio}) : _dio = dio;
  final Dio _dio;

  /// GET /api/v1/user/invite/fetch
  Future<Map<String, dynamic>> getInviteStats() async {
    try {
      final response = await _dio.get('/api/v1/user/invite/fetch');
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      loggy.error('Get invite stats failed', e);
      throw ShareException(_extractErrorMessage(e));
    }
  }

  /// GET /api/v1/user/invite/save
  Future<void> generateInviteCode() async {
    try {
      await _dio.get('/api/v1/user/invite/save');
    } on DioException catch (e) {
      loggy.error('Generate invite code failed', e);
      throw ShareException(_extractErrorMessage(e));
    }
  }

  /// GET /api/v1/user/comm/config
  Future<Map<String, dynamic>> getCommConfig() async {
    try {
      final response = await _dio.get('/api/v1/user/comm/config');
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      loggy.error('Get comm config failed', e);
      throw ShareException(_extractErrorMessage(e));
    }
  }

  String _extractErrorMessage(DioException e) {
    if (e.response?.data is Map) {
      final msg = (e.response!.data as Map)['message'];
      if (msg is String && msg.isNotEmpty) return msg;
    }
    return '请求失败: ${e.message}';
  }
}

class ShareException implements Exception {
  ShareException(this.message);
  final String message;
  @override
  String toString() => 'ShareException: $message';
}
```

- [ ] **Step 2:** Create `lib/features/share/data/share_data_providers.dart`:

```dart
import 'package:hiddify/features/auth/data/auth_data_providers.dart';
import 'package:hiddify/features/share/data/share_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'share_data_providers.g.dart';

@Riverpod(keepAlive: true)
ShareRepository shareRepository(Ref ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return ShareRepository(dio: authRepo.dio);
}
```

- [ ] **Step 3:** Commit: `git add .; git commit -m "feat(share): add share repository and data providers"`

---

### Task 3: Create Model

**Files:**
- Create: `lib/features/share/model/invite_data.dart`

- [ ] **Step 1:** Create `lib/features/share/model/invite_data.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
part 'invite_data.freezed.dart';

@freezed
class InviteData with _$InviteData {
  const InviteData._();

  const factory InviteData({
    required List<String> codes,
    required int inviteCount,
    required int baseRate,
    required bool isDistributionEnabled,
    required double commissionRateL1,
    required double commissionRateL2,
    required double commissionRateL3,
    required int commissionBalance,
    required int pendingAmount,
    required int totalCommission,
    required String currencySymbol,
    required String siteUrl,
  }) = _InviteData;

  String formatAmount(int cents) =>
      '$currencySymbol ${(cents / 100).toStringAsFixed(2)}';

  String inviteUrl(String code) => '$siteUrl/#/register?code=$code';
}
```

- [ ] **Step 2:** Run `dart run build_runner build --delete-conflicting-outputs` to generate freezed files.

- [ ] **Step 3:** Commit: `git add .; git commit -m "feat(share): add InviteData model"`

---

### Task 4: Create Notifier

**Files:**
- Create: `lib/features/share/notifier/share_notifier.dart`

- [ ] **Step 1:** Create `lib/features/share/notifier/share_notifier.dart`:

```dart
import 'package:hiddify/features/auth/data/auth_data_providers.dart';
import 'package:hiddify/features/share/data/share_data_providers.dart';
import 'package:hiddify/features/share/model/invite_data.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'share_notifier.g.dart';

@riverpod
class ShareNotifier extends _$ShareNotifier {
  @override
  Future<InviteData> build() async {
    final repo = ref.read(shareRepositoryProvider);
    final baseUrl = ref.read(authRepositoryProvider).baseUrl;

    final results = await Future.wait([
      repo.getInviteStats(),
      repo.getCommConfig().catchError((_) => <String, dynamic>{}),
    ]);

    final stats = results[0];
    final commConfig = results[1];

    final codes = (stats['codes'] as List? ?? [])
        .map((e) => e is String ? e : (e as Map)['code'] as String)
        .toList();

    final stat = stats['stat'] as List? ?? [0, 0, 0, 0];
    final inviteCount = (stat[0] as num?)?.toInt() ?? 0;
    final totalAmount = (stat[1] as num?)?.toInt() ?? 0;
    final baseRate = (stat.length > 3 ? stat[3] as num? : null)?.toInt() ?? 0;

    final commBalance = (stats['commission_balance'] as num?)?.toInt() ?? 0;
    final pendingAmt = (stats['commission_pending_amount'] as num?)?.toInt() ?? 0;

    final distEnabled = commConfig['commission_distribution_enable'] == 1;
    final l1Pct = (commConfig['commission_distribution_l1'] as num?)?.toDouble() ?? 0;
    final l2Pct = (commConfig['commission_distribution_l2'] as num?)?.toDouble() ?? 0;
    final l3Pct = (commConfig['commission_distribution_l3'] as num?)?.toDouble() ?? 0;

    final rateL1 = distEnabled
        ? double.parse((baseRate * l1Pct / 100).toStringAsFixed(2))
        : baseRate.toDouble();
    final rateL2 = distEnabled
        ? double.parse((baseRate * l2Pct / 100).toStringAsFixed(2))
        : 0.0;
    final rateL3 = distEnabled
        ? double.parse((baseRate * l3Pct / 100).toStringAsFixed(2))
        : 0.0;

    final symbol = (commConfig['currency_symbol'] as String?) ?? '¥';

    return InviteData(
      codes: codes,
      inviteCount: inviteCount,
      baseRate: baseRate,
      isDistributionEnabled: distEnabled,
      commissionRateL1: rateL1,
      commissionRateL2: rateL2,
      commissionRateL3: rateL3,
      commissionBalance: commBalance,
      pendingAmount: pendingAmt,
      totalCommission: totalAmount,
      currencySymbol: symbol,
      siteUrl: baseUrl,
    );
  }

  Future<void> generateCode() async {
    state = const AsyncValue.loading();
    try {
      await ref.read(shareRepositoryProvider).generateInviteCode();
      ref.invalidateSelf();
      await future;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
```

- [ ] **Step 2:** Run `dart run build_runner build --delete-conflicting-outputs`.

- [ ] **Step 3:** Commit: `git add .; git commit -m "feat(share): add ShareNotifier with 3-level commission"`

---

### Task 5: Create Share Page Widget

**Files:**
- Create: `lib/features/share/widget/share_page.dart`

- [ ] **Step 1:** Create `lib/features/share/widget/share_page.dart` with the full page UI. The page should:

1. **AppBar** — back button + centered title `t.pages.share.title`
2. **Commission overview card** — balance large text + stats grid (adapts for 3-level distribution)
3. **Invite code list** — header with generate button + code cards with copy/share buttons
4. **States** — loading shimmer, unauthenticated prompt, error with retry

Use the same styling patterns as `TrafficRecordsPage` and `settings_page.dart`: `surfaceContainerLow`/`surfaceContainer` backgrounds, `primary` accent, `Space Grotesk` headings, rounded corners (16-20), `Gap` for spacing.

Key imports: `share_plus`, `flutter/services.dart` (Clipboard), `ShareNotifier`, auth providers, translations.

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/auth/model/auth_state.dart';
import 'package:hiddify/features/auth/notifier/auth_notifier.dart';
import 'package:hiddify/features/share/notifier/share_notifier.dart';
import 'package:hiddify/features/share/model/invite_data.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:share_plus/share_plus.dart';

class SharePage extends HookConsumerWidget {
  const SharePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = ref.watch(translationsProvider).requireValue;
    final authState = ref.watch(authNotifierProvider);

    if (authState is! Authenticated) {
      return Scaffold(
        appBar: AppBar(
          title: Text(t.pages.share.title,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
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
                Text(t.pages.share.loginRequired,
                    textAlign: TextAlign.center),
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
        title: Text(t.pages.share.title,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
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
              Text('$err'),
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
          Container(height: 160, decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(20),
          )),
          const Gap(24),
          Container(height: 120, decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
          )),
        ],
      ),
    );
  }
}

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
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.pages.share.commissionBalance,
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 1.5,
                color: theme.colorScheme.primary,
              )),
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
          Text(label,
              style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant, fontSize: 10)),
          const Gap(4),
          Text(value,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

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
            Text(t.pages.share.inviteLinks,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            FilledButton.tonalIcon(
              onPressed: isLoading
                  ? null
                  : () => ref
                      .read(shareNotifierProvider.notifier)
                      .generateCode(),
              icon: isLoading
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
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
                Text(t.pages.share.noCodesYet,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          )
        else
          ...data.codes.map((code) =>
              _InviteCodeCard(code: code, data: data, t: t)),
      ],
    );
  }
}

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
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(code,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontFamily: 'monospace',
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                )),
          ),
          const Gap(12),
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
                  horizontal: 12, vertical: 10),
            ),
          ),
          const Gap(12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: url));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(t.pages.share.copied),
                          duration: const Duration(seconds: 1)),
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
```

- [ ] **Step 2:** Commit: `git add .; git commit -m "feat(share): add SharePage widget"`

---

### Task 6: Register Route & Wire Settings Entry

**Files:**
- Modify: `lib/core/router/go_router/routing_config_notifier.dart`
- Modify: `lib/features/settings/overview/settings_page.dart`

- [ ] **Step 1:** In `routing_config_notifier.dart`, add import at the top:

```dart
import 'package:hiddify/features/share/widget/share_page.dart';
```

Add the route inside the settings branch routes list (after the `ticketDetail` route, around line 245):

```dart
GoRoute(
  name: 'share',
  path: '/share',
  pageBuilder: (_, state) => customTransition(
      TransitionType.slide, state.pageKey, const SharePage()),
),
```

- [ ] **Step 2:** In `settings_page.dart` line 285, change:

```dart
_MenuItem(icon: Icons.share_rounded, title: '分享', onTap: () {}),
```

to:

```dart
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
```

- [ ] **Step 3:** Commit: `git add .; git commit -m "feat(share): register route and wire settings entry"`

---

### Task 7: Build & Verify

- [ ] **Step 1:** Run `dart run build_runner build --delete-conflicting-outputs` to ensure all generated files are up to date.

- [ ] **Step 2:** Run `dart run slang` to regenerate translations if not already done.

- [ ] **Step 3:** Build and run the app: `flutter run` — verify:
  - Settings page "分享" / "Invite & Earn" menu item navigates to share page
  - Unauthenticated users see login prompt
  - Authenticated users see commission stats + invite codes
  - Generate code button works
  - Copy link copies to clipboard with SnackBar feedback
  - Share button opens system share dialog
  - Three-level commission rates display correctly (when enabled)

- [ ] **Step 4:** Final commit: `git add .; git commit -m "feat(share): complete share page implementation"`
