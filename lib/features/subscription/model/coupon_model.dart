import 'package:freezed_annotation/freezed_annotation.dart';

part 'coupon_model.freezed.dart';
part 'coupon_model.g.dart';

@freezed
class CouponModel with _$CouponModel {
  const CouponModel._();

  const factory CouponModel({
    /// Coupon type: 1=fixed amount (cents), 2=percentage.
    required int type,

    /// Value: for type=1 it's cents, for type=2 it's percentage (e.g. 10 = 10%).
    required int value,

    /// Coupon display name.
    String? name,
  }) = _CouponModel;

  factory CouponModel.fromJson(Map<String, Object?> json) =>
      _$CouponModelFromJson(json);

  /// Calculate the discount amount in cents for a given price (in cents).
  int discountFor(int priceCents) {
    if (type == 1) return value;
    if (type == 2) return (priceCents * value / 100).round();
    return 0;
  }
}
