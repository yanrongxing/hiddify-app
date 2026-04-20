import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hiddify/core/model/environment.dart';
import 'package:hiddify/core/utils/exception_handler.dart';
import 'package:hiddify/features/app_update/model/app_update_failure.dart';
import 'package:hiddify/features/app_update/model/remote_version_entity.dart';
import 'package:hiddify/utils/utils.dart';

abstract interface class AppUpdateRepository {
  TaskEither<AppUpdateFailure, RemoteVersionEntity> getLatestVersion({
    bool includePreReleases = false,
    Release release = Release.general,
  });
}

class AppUpdateRepositoryImpl with ExceptionHandler, InfraLogger implements AppUpdateRepository {
  AppUpdateRepositoryImpl({required this.dio});

  final Dio dio;

  @override
  TaskEither<AppUpdateFailure, RemoteVersionEntity> getLatestVersion({
    bool includePreReleases = false,
    Release release = Release.general,
  }) {
    return exceptionHandler(() async {
      String osIdentifier = "macOS";
      if (Platform.isWindows) {
        osIdentifier = "Windows";
      } else if (Platform.isAndroid) {
        osIdentifier = "Android";
      } else if (Platform.isIOS) {
        osIdentifier = "iOS";
      }

      final customUserAgent = "tidalab/4.0.0 $osIdentifier";

      try {
        final response = await dio.get(
          '/api/v1/client/app/getVersion',
          options: Options(
            headers: {
              'User-Agent': customUserAgent,
            },
          ),
        );

        loggy.debug("getVersion response status: ${response.statusCode}, data: ${response.data}");

        if (response.statusCode != 200 || response.data == null || response.data['data'] == null) {
          loggy.warning("failed to fetch latest version info, status: ${response.statusCode}");
          return left(const AppUpdateFailure.unexpected());
        }

        final data = response.data['data'];
        final rawForce = data['is_force_update'];
        print('[REPO] raw is_force_update value: $rawForce (type: ${rawForce.runtimeType})');
        final isForce = rawForce?.toString() == "1" || rawForce?.toString().toLowerCase() == "true" || rawForce == true || rawForce == 1;
        print('[REPO] parsed isForceUpdate: $isForce');
        final latest = RemoteVersionEntity(
          version: data['version'] as String? ?? "",
          url: data['download_url'] as String? ?? "",
          isForceUpdate: isForce,
          updateContent: data['update_content'] as String? ?? "",
        );

        return right(latest);
      } on DioException catch (e) {
        loggy.error("DioException getting version:\nType: ${e.type}\nMessage: ${e.message}\nBaseURL: ${dio.options.baseUrl}\nResponse: ${e.response?.data}\nFull Exception: $e");
        return left(AppUpdateFailure.unexpected(e));
      } catch (e) {
        loggy.error("Unknown exception getting version: $e");
        return left(AppUpdateFailure.unexpected(e));
      }
    }, AppUpdateFailure.unexpected);
  }
}
