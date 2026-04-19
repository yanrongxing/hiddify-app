import 'package:dio/dio.dart';
import 'package:hiddify/features/ticket/model/ticket_model.dart';
import 'package:hiddify/features/ticket/model/ticket_message_model.dart';
import 'package:hiddify/utils/custom_loggers.dart';

class TicketRepository with InfraLogger {
  TicketRepository({required Dio dio}) : _dio = dio;
  final Dio _dio;

  Future<List<TicketModel>> fetchTickets() async {
    try {
      final response = await _dio.get('/api/v1/user/ticket/fetch');
      final dataList = response.data['data'] as List? ?? [];
      return dataList.map((e) => TicketModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      loggy.error('Fetch tickets failed', e);
      throw TicketException(_extractErrorMessage(e));
    }
  }

  Future<List<TicketMessageModel>> fetchTicketMessages(int ticketId) async {
    try {
      final response = await _dio.get('/api/v1/user/ticket/fetch', queryParameters: {'id': ticketId});
      final dataObj = response.data['data'] as Map<String, dynamic>? ?? {};
      final dataList = dataObj['message'] as List? ?? [];
      return dataList.map((e) => TicketMessageModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      loggy.error('Fetch ticket messages failed', e);
      throw TicketException(_extractErrorMessage(e));
    }
  }

  Future<void> createTicket({required String subject, required int level, required String message}) async {
    try {
      await _dio.post('/api/v1/user/ticket/save', data: {'subject': subject, 'level': level, 'message': message});
    } on DioException catch (e) {
      loggy.error('Create ticket failed', e);
      throw TicketException(_extractErrorMessage(e));
    }
  }

  Future<void> replyTicket(int id, String message) async {
    try {
      await _dio.post('/api/v1/user/ticket/reply', data: {'id': id, 'message': message});
    } on DioException catch (e) {
      loggy.error('Reply ticket failed', e);
      throw TicketException(_extractErrorMessage(e));
    }
  }

  Future<void> closeTicket(int id) async {
    try {
      await _dio.post('/api/v1/user/ticket/close', data: {'id': id});
    } on DioException catch (e) {
      loggy.error('Close ticket failed', e);
      throw TicketException(_extractErrorMessage(e));
    }
  }

  String _extractErrorMessage(DioException e) {
    if (e.response?.data is Map) {
      final msg = (e.response!.data as Map)['message'];
      if (msg is String && msg.isNotEmpty) return msg;
    }
    return '请求失败: ${e.message}';
  }
}

class TicketException implements Exception {
  TicketException(this.message);
  final String message;
  @override
  String toString() => 'TicketException: $message';
}
