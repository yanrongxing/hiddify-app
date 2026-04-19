import 'package:freezed_annotation/freezed_annotation.dart';

part 'plan_model.freezed.dart';
part 'plan_model.g.dart';

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
class PlanModel with _$PlanModel {
  const PlanModel._();

  const factory PlanModel({
    /// Plan ID.
    @JsonKey(fromJson: _parseInt) required int id,

    /// Plan display name.
    required String name,

    /// Markdown description of the plan.
    String? content,

    /// Traffic allowance in GB.
    @JsonKey(name: 'transfer_enable', fromJson: _parseIntNullable) int? transferEnable,

    /// Speed limit in Mbps (null = unlimited).
    @JsonKey(name: 'speed_limit', fromJson: _parseIntNullable) int? speedLimit,

    /// Max concurrent devices (null = unlimited).
    @JsonKey(name: 'device_limit', fromJson: _parseIntNullable) int? deviceLimit,

    /// Monthly price in cents.
    @JsonKey(name: 'month_price', fromJson: _parseIntNullable) int? monthPrice,

    /// Quarterly price in cents.
    @JsonKey(name: 'quarter_price', fromJson: _parseIntNullable) int? quarterPrice,

    /// Half-year price in cents.
    @JsonKey(name: 'half_year_price', fromJson: _parseIntNullable) int? halfYearPrice,

    /// Yearly price in cents.
    @JsonKey(name: 'year_price', fromJson: _parseIntNullable) int? yearPrice,

    /// Two-year price in cents.
    @JsonKey(name: 'two_year_price', fromJson: _parseIntNullable) int? twoYearPrice,

    /// Three-year price in cents.
    @JsonKey(name: 'three_year_price', fromJson: _parseIntNullable) int? threeYearPrice,

    /// One-time price in cents.
    @JsonKey(name: 'onetime_price', fromJson: _parseIntNullable) int? onetimePrice,
  }) = _PlanModel;

  factory PlanModel.fromJson(Map<String, Object?> json) =>
      _$PlanModelFromJson(json);

  /// Returns the lowest available price across all periods (in cents).
  int? get lowestPrice {
    final prices = [
      monthPrice,
      quarterPrice,
      halfYearPrice,
      yearPrice,
      twoYearPrice,
      threeYearPrice,
      onetimePrice,
    ].whereType<int>();
    if (prices.isEmpty) return null;
    return prices.reduce((a, b) => a < b ? a : b);
  }
}
