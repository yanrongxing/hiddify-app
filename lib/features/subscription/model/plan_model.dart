import 'package:freezed_annotation/freezed_annotation.dart';

part 'plan_model.freezed.dart';
part 'plan_model.g.dart';

@freezed
class PlanModel with _$PlanModel {
  const PlanModel._();

  const factory PlanModel({
    /// Plan ID.
    required int id,

    /// Plan display name.
    required String name,

    /// Markdown description of the plan.
    String? content,

    /// Traffic allowance in GB.
    @JsonKey(name: 'transfer_enable') int? transferEnable,

    /// Speed limit in Mbps (null = unlimited).
    @JsonKey(name: 'speed_limit') int? speedLimit,

    /// Max concurrent devices (null = unlimited).
    @JsonKey(name: 'device_limit') int? deviceLimit,

    /// Monthly price in cents.
    @JsonKey(name: 'month_price') int? monthPrice,

    /// Quarterly price in cents.
    @JsonKey(name: 'quarter_price') int? quarterPrice,

    /// Half-year price in cents.
    @JsonKey(name: 'half_year_price') int? halfYearPrice,

    /// Yearly price in cents.
    @JsonKey(name: 'year_price') int? yearPrice,

    /// Two-year price in cents.
    @JsonKey(name: 'two_year_price') int? twoYearPrice,

    /// Three-year price in cents.
    @JsonKey(name: 'three_year_price') int? threeYearPrice,

    /// One-time price in cents.
    @JsonKey(name: 'onetime_price') int? onetimePrice,
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
