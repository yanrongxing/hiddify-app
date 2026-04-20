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

  /// Format an amount in cents to display string.
  String formatAmount(int cents) =>
      '$currencySymbol ${(cents / 100).toStringAsFixed(2)}';

  /// Generate the full invite URL for a given code.
  String inviteUrl(String code) => '$siteUrl/#/register?code=$code';
}
