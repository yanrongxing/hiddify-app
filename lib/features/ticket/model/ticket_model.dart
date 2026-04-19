import 'package:freezed_annotation/freezed_annotation.dart';
part 'ticket_model.freezed.dart';
part 'ticket_model.g.dart';

@freezed
class TicketModel with _$TicketModel {
  const TicketModel._();
  const factory TicketModel({
    required int id,
    required String subject,
    required int level,
    required int status,
    @JsonKey(name: 'created_at') required int createdAt,
    @JsonKey(name: 'updated_at') required int updatedAt,
    @JsonKey(name: 'reply_status') @Default(0) int replyStatus,
  }) = _TicketModel;

  factory TicketModel.fromJson(Map<String, Object?> json) =>
      _$TicketModelFromJson(json);

  /// status: 0=Pending, 1=Closed, 2=Replied
  bool get isClosed => status == 1;
}
