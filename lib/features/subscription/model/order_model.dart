import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hiddify/features/subscription/model/plan_model.dart';

part 'order_model.freezed.dart';
part 'order_model.g.dart';

@freezed
class OrderModel with _$OrderModel {
  const OrderModel._();

  const factory OrderModel({
    /// Trade number (order ID).
    @JsonKey(name: 'trade_no') required String tradeNo,

    /// Order status: 0=pending, 1=processing, 2=cancelled, 3=completed, 4=offset.
    required int status,

    /// Total amount in cents.
    @JsonKey(name: 'total_amount') required int totalAmount,

    /// Discount amount in cents.
    @JsonKey(name: 'discount_amount') @Default(0) int discountAmount,

    /// Handling fee in cents.
    @JsonKey(name: 'handling_amount') @Default(0) int handlingAmount,

    /// Billing period key (e.g. 'month_price').
    String? period,

    /// Associated plan details.
    PlanModel? plan,

    /// Unix timestamp of creation.
    @JsonKey(name: 'created_at') int? createdAt,
  }) = _OrderModel;

  factory OrderModel.fromJson(Map<String, Object?> json) =>
      _$OrderModelFromJson(json);

  /// Format total as display string (cents → yuan).
  String get totalDisplay => (totalAmount / 100).toStringAsFixed(2);

  /// Format discount as display string.
  String get discountDisplay => (discountAmount / 100).toStringAsFixed(2);

  /// Whether the order is pending payment.
  bool get isPending => status == 0;

  /// Whether the order is completed.
  bool get isCompleted => status == 3;

  /// Status display text.
  String get statusText => switch (status) {
        0 => '待支付',
        1 => '处理中',
        2 => '已取消',
        3 => '已完成',
        4 => '已折抵',
        _ => '未知',
      };
}
