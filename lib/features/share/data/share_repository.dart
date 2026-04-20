import 'package:dio/dio.dart';
import 'package:hiddify/utils/custom_loggers.dart';

class ShareRepository with InfraLogger {
  ShareRepository({required Dio dio}) : _dio = dio;
  final Dio _dio;

  /// GET /api/v1/user/invite/fetch
  Future<Map<String, dynamic>> getInviteStats() async {
    try {
      final response = await _dio.get('/api/v1/user/invite/fetch');
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      loggy.error('Get invite stats failed', e);
      throw ShareException(_extractErrorMessage(e));
    }
  }

  /// GET /api/v1/user/invite/save
  Future<void> generateInviteCode() async {
    try {
      await _dio.get('/api/v1/user/invite/save');
    } on DioException catch (e) {
      loggy.error('Generate invite code failed', e);
      throw ShareException(_extractErrorMessage(e));
    }
  }

  /// GET /api/v1/user/comm/config
  Future<Map<String, dynamic>> getCommConfig() async {
    try {
      final response = await _dio.get('/api/v1/user/comm/config');
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      loggy.error('Get comm config failed', e);
      throw ShareException(_extractErrorMessage(e));
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

class ShareException implements Exception {
  ShareException(this.message);
  final String message;
  @override
  String toString() => 'ShareException: $message';
}
