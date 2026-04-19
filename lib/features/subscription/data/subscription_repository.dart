import 'package:dio/dio.dart';
import 'package:hiddify/features/subscription/model/coupon_model.dart';
import 'package:hiddify/features/subscription/model/order_model.dart';
import 'package:hiddify/features/subscription/model/payment_method_model.dart';
import 'package:hiddify/features/subscription/model/plan_model.dart';
import 'package:hiddify/features/subscription/model/subscribe_info_model.dart';
import 'package:hiddify/utils/custom_loggers.dart';

/// Repository for Xboard subscription API calls.
class SubscriptionRepository with InfraLogger {
  SubscriptionRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  /// Fetch available plans.
  /// GET /api/v1/guest/plan/fetch
  Future<List<PlanModel>> fetchPlans() async {
    try {
      final response = await _dio.get('/api/v1/guest/plan/fetch');
      final dataList = response.data['data'] as List;
      return dataList.map((e) => PlanModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      loggy.error('Fetch plans failed', e);
      throw SubscriptionException(_extractErrorMessage(e));
    }
  }

  /// Get current user subscription info.
  /// GET /api/v1/user/getSubscribe
  Future<SubscribeInfoModel> getSubscribeInfo() async {
    try {
      final response = await _dio.get('/api/v1/user/getSubscribe');
      return SubscribeInfoModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      loggy.error('Get subscribe info failed', e);
      throw SubscriptionException(_extractErrorMessage(e));
    }
  }

  /// Check coupon validity.
  /// POST /api/v1/user/coupon/check
  Future<CouponModel> checkCoupon(String code, int planId, String period) async {
    try {
      final response = await _dio.post(
        '/api/v1/user/coupon/check',
        data: {
          'code': code,
          'plan_id': planId,
          'period': period,
        },
      );
      return CouponModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      loggy.warning('Check coupon failed', e);
      throw SubscriptionException(_extractErrorMessage(e));
    }
  }

  /// Fetch user orders.
  /// GET /api/v1/user/order/fetch
  Future<List<OrderModel>> fetchOrders({int? status}) async {
    try {
      final queryParams = status != null ? {'status': status} : null;
      final response = await _dio.get('/api/v1/user/order/fetch', queryParameters: queryParams);
      final dataList = response.data['data'] as List;
      return dataList.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      loggy.error('Fetch orders failed', e);
      throw SubscriptionException(_extractErrorMessage(e));
    }
  }

  /// Cancel an order.
  /// POST /api/v1/user/order/cancel
  Future<void> cancelOrder(String tradeNo) async {
    try {
      await _dio.post(
        '/api/v1/user/order/cancel',
        data: {'trade_no': tradeNo},
      );
    } on DioException catch (e) {
      loggy.error('Cancel order failed', e);
      throw SubscriptionException(_extractErrorMessage(e));
    }
  }

  /// Create a new order.
  /// POST /api/v1/user/order/save
  /// Returns the generated trade number.
  Future<String> createOrder(int planId, String period, {String? couponCode}) async {
    try {
      final response = await _dio.post(
        '/api/v1/user/order/save',
        data: {
          'plan_id': planId,
          'period': period,
          if (couponCode != null && couponCode.isNotEmpty) 'coupon_code': couponCode,
        },
      );
      return response.data['data'] as String;
    } on DioException catch (e) {
      loggy.error('Create order failed', e);
      throw SubscriptionException(_extractErrorMessage(e));
    }
  }

  /// Get order details.
  /// GET /api/v1/user/order/detail
  Future<OrderModel> getOrderDetail(String tradeNo) async {
    try {
      loggy.info('[getOrderDetail] request -> trade_no: $tradeNo');
      final response = await _dio.get('/api/v1/user/order/detail', queryParameters: {'trade_no': tradeNo});
      loggy.info('[getOrderDetail] response -> ${response.data}');
      return OrderModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      loggy.error('Get order detail failed', e);
      throw SubscriptionException(_extractErrorMessage(e));
    }
  }

  /// Get available payment methods.
  /// GET /api/v1/user/order/getPaymentMethod
  Future<List<PaymentMethodModel>> getPaymentMethods() async {
    try {
      final response = await _dio.get('/api/v1/user/order/getPaymentMethod');
      final dataList = response.data['data'] as List;
      return dataList.map((e) => PaymentMethodModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      loggy.error('Get payment methods failed', e);
      throw SubscriptionException(_extractErrorMessage(e));
    }
  }

  /// Execute checkout.
  /// POST /api/v1/user/order/checkout
  Future<Map<String, dynamic>> checkout(String tradeNo, int method) async {
    try {
      final requestData = {
        'trade_no': tradeNo,
        'method': method,
      };
      loggy.info('[checkout] request -> $requestData');
      final response = await _dio.post(
        '/api/v1/user/order/checkout',
        data: requestData,
      );
      loggy.info('[checkout] raw response.data -> ${response.data}');
      // Returns type (0=URL, -1=offset) and data (the URL or true)
      final result = {
        'type': response.data['type'],
        'data': response.data['data'],
      };
      loggy.info('[checkout] parsed result -> type=${result["type"]} (${result["type"]?.runtimeType}), data=${result["data"]} (${result["data"]?.runtimeType})');
      return result;
    } on DioException catch (e) {
      loggy.error('Checkout failed', e);
      throw SubscriptionException(_extractErrorMessage(e));
    }
  }

  /// Check order status (for polling).
  /// GET /api/v1/user/order/check
  Future<int> checkOrderStatus(String tradeNo) async {
    try {
      final response = await _dio.get('/api/v1/user/order/check', queryParameters: {'trade_no': tradeNo});
      // Assuming response.data['data'] is the status or trade_no status string.
      // xboard /check returns boolean true if completed, or it might return the status directly.
      // Let's handle both. Actually, xboard's /order/check returns boolean true/false.
      // If data is bool, return 3 if true, 0 if false.
      final data = response.data['data'];
      if (data is bool) {
        return data ? 3 : 0;
      }
      return data as int;
    } on DioException catch (e) {
      loggy.error('Check order status failed', e);
      throw SubscriptionException(_extractErrorMessage(e));
    }
  }

  String _extractErrorMessage(DioException e) {
    if (e.response?.data is Map) {
      final msg = (e.response!.data as Map)['message'];
      if (msg is String && msg.isNotEmpty) return msg;
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return '网络连接超时，请重试';
      case DioExceptionType.connectionError:
        return '无法连接到服务器';
      default:
        return '请求失败: ${e.message}';
    }
  }
}

/// Exception thrown by [SubscriptionRepository] operations.
class SubscriptionException implements Exception {
  SubscriptionException(this.message);

  final String message;

  @override
  String toString() => 'SubscriptionException: $message';
}
