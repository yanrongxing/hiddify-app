import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment_method_model.freezed.dart';
part 'payment_method_model.g.dart';

@freezed
class PaymentMethodModel with _$PaymentMethodModel {
  const factory PaymentMethodModel({
    /// Payment method ID.
    required int id,

    /// Display name.
    required String name,

    /// Icon URL or identifier.
    String? icon,

    /// Payment gateway type/identifier.
    int? payment,
  }) = _PaymentMethodModel;

  factory PaymentMethodModel.fromJson(Map<String, Object?> json) =>
      _$PaymentMethodModelFromJson(json);
}
