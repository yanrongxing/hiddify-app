import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hiddify/features/subscription/model/plan_model.dart';

part 'order_model.freezed.dart';
part 'order_model.g.dart';

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
class OrderModel with _$OrderModel {
  const OrderModel._();

  const factory OrderModel({
    /// Trade number (order ID).
    @JsonKey(name: 'trade_no') required String tradeNo,

    /// Order status: 0=pending, 1=processing, 2=cancelled, 3=completed, 4=offset.
    @JsonKey(fromJson: _parseInt) required int status,

    /// Total amount in cents.
    @JsonKey(name: 'total_amount', fromJson: _parseInt) required int totalAmount,

    /// Discount amount in cents.
    @JsonKey(name: 'discount_amount', fromJson: _parseInt) @Default(0) int discountAmount,

    /// Handling fee in cents.
    @JsonKey(name: 'handling_amount', fromJson: _parseInt) @Default(0) int handlingAmount,

    /// Billing period key (e.g. 'month_price').
    String? period,

    /// Associated plan details.
    PlanModel? plan,

    /// Unix timestamp of creation.
    @JsonKey(name: 'created_at', fromJson: _parseIntNullable) int? createdAt,
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
