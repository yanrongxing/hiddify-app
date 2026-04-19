import 'package:dio/dio.dart';
import 'package:hiddify/features/traffic/model/traffic_log_model.dart';
import 'package:hiddify/utils/custom_loggers.dart';

class TrafficRepository with InfraLogger {
  TrafficRepository({required Dio dio}) : _dio = dio;
  final Dio _dio;

  Future<List<TrafficLogModel>> getTrafficLog() async {
    try {
      final response = await _dio.get('/api/v1/user/stat/getTrafficLog');
      final dataList = response.data['data'] as List? ?? [];
      return dataList
          .map((e) => TrafficLogModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      loggy.error('Get traffic log failed', e);
      throw TrafficException(_extractErrorMessage(e));
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

class TrafficException implements Exception {
  TrafficException(this.message);
  final String message;
  @override
  String toString() => 'TrafficException: $message';
}
