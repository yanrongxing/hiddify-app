import 'package:freezed_annotation/freezed_annotation.dart';
part 'ticket_message_model.freezed.dart';
part 'ticket_message_model.g.dart';

@freezed
class TicketMessageModel with _$TicketMessageModel {
  const factory TicketMessageModel({
    int? id,
    @JsonKey(name: 'user_id') int? userId,
    required String message,
    @JsonKey(name: 'created_at') required int createdAt,
    @JsonKey(name: 'is_me') @Default(false) bool isMe,
  }) = _TicketMessageModel;

  factory TicketMessageModel.fromJson(Map<String, Object?> json) =>
      _$TicketMessageModelFromJson(json);
}
