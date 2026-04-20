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

    // Concurrent fetch of invite stats and commission config.
    final results = await Future.wait([
      repo.getInviteStats(),
      repo.getCommConfig().catchError((_) => <String, dynamic>{}),
    ]);

    final stats = results[0];
    final commConfig = results[1];

    // Parse invite codes.
    final codes = (stats['codes'] as List? ?? [])
        .map((e) => e is String ? e : (e as Map)['code'] as String)
        .toList();

    // Parse statistics array: [invite_count, total_commission, unknown, base_rate].
    final stat = stats['stat'] as List? ?? [0, 0, 0, 0];
    final inviteCount = (stat[0] as num?)?.toInt() ?? 0;
    final totalAmount = (stat[1] as num?)?.toInt() ?? 0;
    final baseRate = (stat.length > 3 ? stat[3] as num? : null)?.toInt() ?? 0;

    final commBalance = (stats['commission_balance'] as num?)?.toInt() ?? 0;
    final pendingAmt =
        (stats['commission_pending_amount'] as num?)?.toInt() ?? 0;

    // Three-level distribution calculation (mirrors Invite.jsx logic).
    final distEnabled = commConfig['commission_distribution_enable'] == 1;
    final l1Pct =
        (commConfig['commission_distribution_l1'] as num?)?.toDouble() ?? 0;
    final l2Pct =
        (commConfig['commission_distribution_l2'] as num?)?.toDouble() ?? 0;
    final l3Pct =
        (commConfig['commission_distribution_l3'] as num?)?.toDouble() ?? 0;

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

  /// Generate a new invite code and refresh the state.
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
