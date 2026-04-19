import 'package:freezed_annotation/freezed_annotation.dart';
part 'traffic_log_model.freezed.dart';
part 'traffic_log_model.g.dart';

@freezed
class TrafficLogModel with _$TrafficLogModel {
  const factory TrafficLogModel({
    @JsonKey(name: 'record_at') required int recordAt,
    @Default(0) int u,
    @Default(0) int d,
    @JsonKey(name: 'server_rate') @Default(1.0) double serverRate,
  }) = _TrafficLogModel;

  factory TrafficLogModel.fromJson(Map<String, Object?> json) =>
      _$TrafficLogModelFromJson(json);
}
