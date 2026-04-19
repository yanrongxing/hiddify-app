import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:hiddify/features/auth/model/user_model.dart';
import 'package:hiddify/utils/custom_loggers.dart';

/// Repository for Xboard authentication API calls.
///
/// API base URL should be configured to point to your Xboard instance.
class AuthRepository with InfraLogger {
  AuthRepository({
    required this.baseUrl,
    Dio? dio,
  }) : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl,
                connectTimeout: const Duration(seconds: 15),
                sendTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            ) {
    // Bypass SSL verification for IP-based or invalid certs.
    _dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
        return client;
      },
    );

    _dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        error: true,
        logPrint: (obj) => loggy.debug(obj.toString()),
      ),
    );
  }

  final String baseUrl;
  final Dio _dio;

  /// Set the authorization token for subsequent requests.
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = token;
  }

  /// Clear the authorization token.
  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  /// Login with email and password.
  ///
  /// Returns the auth token on success.
  /// POST /api/v1/passport/auth/login
  Future<({String token, UserModel user})> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/passport/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      final data = response.data['data'] as Map<String, dynamic>;
      final token = data['auth_data'] as String;

      setAuthToken(token);

      // Fetch user info after login
      final user = await getUserInfo();

      return (token: token, user: user);
    } on DioException catch (e) {
      loggy.error('Login failed', e);
      final message = _extractErrorMessage(e);
      throw AuthException(message);
    }
  }

  /// Register a new account.
  ///
  /// POST /api/v1/passport/auth/register
  Future<({String token, UserModel user})> register({
    required String email,
    required String password,
    String? inviteCode,
    String? emailCode,
  }) async {
    try {
      final body = <String, dynamic>{
        'email': email,
        'password': password,
      };
      if (inviteCode != null && inviteCode.isNotEmpty) {
        body['invite_code'] = inviteCode;
      }
      if (emailCode != null && emailCode.isNotEmpty) {
        body['email_code'] = emailCode;
      }

      final response = await _dio.post(
        '/api/v1/passport/auth/register',
        data: body,
      );

      final data = response.data['data'] as Map<String, dynamic>;
      final token = data['auth_data'] as String;

      setAuthToken(token);
      final user = await getUserInfo();

      return (token: token, user: user);
    } on DioException catch (e) {
      loggy.error('Register failed', e);
      final message = _extractErrorMessage(e);
      throw AuthException(message);
    }
  }

  /// Send password reset email.
  ///
  /// POST /api/v1/passport/comm/sendEmailVerify
  Future<void> sendResetEmail(String email) async {
    try {
      await _dio.post(
        '/api/v1/passport/comm/sendEmailVerify',
        data: {'email': email},
      );
    } on DioException catch (e) {
      loggy.error('Send reset email failed', e);
      final message = _extractErrorMessage(e);
      throw AuthException(message);
    }
  }

  /// Reset password with email code.
  ///
  /// POST /api/v1/passport/auth/forget
  Future<void> resetPassword({
    required String email,
    required String emailCode,
    required String newPassword,
  }) async {
    try {
      await _dio.post(
        '/api/v1/passport/auth/forget',
        data: {
          'email': email,
          'email_code': emailCode,
          'password': newPassword,
        },
      );
    } on DioException catch (e) {
      loggy.error('Reset password failed', e);
      final message = _extractErrorMessage(e);
      throw AuthException(message);
    }
  }

  /// Get site configuration (guest endpoint, no auth needed).
  ///
  /// GET /api/v1/guest/comm/config
  /// Returns config with `is_email_verify`, `is_invite_force`, etc.
  Future<Map<String, dynamic>> getSiteConfig() async {
    try {
      final response = await _dio.get('/api/v1/guest/comm/config');
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      loggy.error('Get site config failed', e);
      final message = _extractErrorMessage(e);
      throw AuthException(message);
    }
  }

  /// Get current user info.
  ///
  /// GET /api/v1/user/info
  Future<UserModel> getUserInfo() async {
    try {
      final response = await _dio.get('/api/v1/user/info');
      final data = response.data['data'] as Map<String, dynamic>;
      return UserModel.fromJson(data);
    } on DioException catch (e) {
      loggy.error('Get user info failed', e);
      final message = _extractErrorMessage(e);
      throw AuthException(message);
    }
  }

  /// Get the subscription URL for the current user.
  ///
  /// GET /api/v1/user/getSubscribe
  Future<String> getSubscribeUrl() async {
    try {
      final response = await _dio.get('/api/v1/user/getSubscribe');
      final data = response.data['data'] as Map<String, dynamic>;
      final subscribeUrl = data['subscribe_url'] as String;
      return subscribeUrl;
    } on DioException catch (e) {
      loggy.error('Get subscribe URL failed', e);
      final message = _extractErrorMessage(e);
      throw AuthException(message);
    }
  }

  /// Logout (client-side only — clear token).
  void logout() {
    clearAuthToken();
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

/// Exception thrown by [AuthRepository] operations.
class AuthException implements Exception {
  AuthException(this.message);

  final String message;

  @override
  String toString() => 'AuthException: $message';
}
