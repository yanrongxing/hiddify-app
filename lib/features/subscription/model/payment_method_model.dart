import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment_method_model.freezed.dart';
part 'payment_method_model.g.dart';

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
class PaymentMethodModel with _$PaymentMethodModel {
  const factory PaymentMethodModel({
    /// Payment method ID.
    @JsonKey(fromJson: _parseInt) required int id,

    /// Display name.
    required String name,

    /// Icon URL or identifier.
    String? icon,

    /// Payment gateway type/identifier.
    @JsonKey(fromJson: _parseIntNullable) int? payment,
  }) = _PaymentMethodModel;

  factory PaymentMethodModel.fromJson(Map<String, Object?> json) =>
      _$PaymentMethodModelFromJson(json);
}
