import 'package:freezed_annotation/freezed_annotation.dart';
part 'traffic_log_model.freezed.dart';
part 'traffic_log_model.g.dart';

int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

double _parseDouble(dynamic value) {
  if (value == null) return 1.0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 1.0;
  return 1.0;
}

@freezed
class TrafficLogModel with _$TrafficLogModel {
  const factory TrafficLogModel({
    @JsonKey(name: 'record_at', fromJson: _parseInt) required int recordAt,
    @JsonKey(fromJson: _parseInt) @Default(0) int u,
    @JsonKey(fromJson: _parseInt) @Default(0) int d,
    @JsonKey(name: 'server_rate', fromJson: _parseDouble) @Default(1.0) double serverRate,
  }) = _TrafficLogModel;

  factory TrafficLogModel.fromJson(Map<String, Object?> json) =>
      _$TrafficLogModelFromJson(json);
}
