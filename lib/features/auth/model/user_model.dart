import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
class UserModel with _$UserModel {
  const UserModel._();

  const factory UserModel({
    /// User email address.
    required String email,

    /// UUID from Xboard backend.
    String? uuid,

    /// Avatar URL if available.
    String? avatarUrl,

    /// Remaining balance in cents.
    @Default(0) int balance,

    /// Commission balance in cents.
    @Default(0) int commissionBalance,

    /// Invite code for referrals.
    String? inviteCode,

    /// Unix timestamp of when the user was created.
    int? createdAt,

    /// Active plan ID.
    @JsonKey(name: 'plan_id') int? planId,

    /// Uploaded traffic in bytes.
    @Default(0) int u,

    /// Downloaded traffic in bytes.
    @Default(0) int d,

    /// Total allowed traffic in bytes.
    @JsonKey(name: 'transfer_enable') @Default(0) int transferEnable,

    /// Unix timestamp of expiration.
    @JsonKey(name: 'expired_at') int? expiredAt,

    /// Subscription URL.
    @JsonKey(name: 'subscribe_url') String? subscribeUrl,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, Object?> json) =>
      _$UserModelFromJson(json);

  /// Format balance as display string (in cents → yuan/dollar).
  String get balanceDisplay => (balance / 100).toStringAsFixed(2);
}
