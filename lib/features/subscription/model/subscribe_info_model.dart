import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hiddify/features/subscription/model/plan_model.dart';

part 'subscribe_info_model.freezed.dart';
part 'subscribe_info_model.g.dart';

@freezed
class SubscribeInfoModel with _$SubscribeInfoModel {
  const SubscribeInfoModel._();

  const factory SubscribeInfoModel({
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

    /// Plan details if included in response.
    PlanModel? plan,
  }) = _SubscribeInfoModel;

  factory SubscribeInfoModel.fromJson(Map<String, Object?> json) =>
      _$SubscribeInfoModelFromJson(json);

  /// Total traffic used in bytes.
  int get totalUsed => u + d;

  /// Remaining traffic in bytes.
  int get remaining => transferEnable > totalUsed ? transferEnable - totalUsed : 0;
}
