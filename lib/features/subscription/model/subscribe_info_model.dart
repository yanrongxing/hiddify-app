import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hiddify/features/subscription/model/plan_model.dart';

part 'subscribe_info_model.freezed.dart';
part 'subscribe_info_model.g.dart';

int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

int? _parseIntNullable(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

@freezed
class SubscribeInfoModel with _$SubscribeInfoModel {
  const SubscribeInfoModel._();

  const factory SubscribeInfoModel({
    /// Active plan ID.
    @JsonKey(name: 'plan_id', fromJson: _parseIntNullable) int? planId,

    /// Uploaded traffic in bytes.
    @JsonKey(fromJson: _parseInt) @Default(0) int u,

    /// Downloaded traffic in bytes.
    @JsonKey(fromJson: _parseInt) @Default(0) int d,

    /// Total allowed traffic in bytes.
    @JsonKey(name: 'transfer_enable', fromJson: _parseInt) @Default(0) int transferEnable,

    /// Unix timestamp of expiration.
    @JsonKey(name: 'expired_at', fromJson: _parseIntNullable) int? expiredAt,

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
