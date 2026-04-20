import 'package:hiddify/core/app_info/app_info_provider.dart';
import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/core/utils/preferences_utils.dart';
import 'package:hiddify/features/app_update/data/app_update_data_providers.dart';
import 'package:hiddify/features/app_update/model/app_update_failure.dart';
import 'package:hiddify/features/app_update/model/remote_version_entity.dart';
import 'package:hiddify/features/app_update/notifier/app_update_state.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:version/version.dart';

part 'app_update_notifier.g.dart';

@Riverpod(keepAlive: true)
class AppUpdateNotifier extends _$AppUpdateNotifier with AppLogger {
  @override
  AppUpdateState build() => const AppUpdateState.initial();

  PreferencesEntry<String?, dynamic> get _ignoreReleasePref => PreferencesEntry(
    preferences: ref.read(sharedPreferencesProvider).requireValue,
    key: 'ignored_release_version',
    defaultValue: null,
  );

  Future<AppUpdateState> check() async {
    print('[CHECK_UPDATE] ===== check() called =====');
    state = const AppUpdateState.checking();

    try {
      final appInfoAsync = ref.read(appInfoProvider);
      print('[CHECK_UPDATE] appInfoAsync: isLoading=${appInfoAsync.isLoading}, hasValue=${appInfoAsync.hasValue}, hasError=${appInfoAsync.hasError}');
      if (appInfoAsync.isLoading || !appInfoAsync.hasValue) {
        print('[CHECK_UPDATE] appInfo not ready, aborting');
        return state = const AppUpdateState.initial();
      }
      final appInfo = appInfoAsync.requireValue;
      print('[CHECK_UPDATE] current app version: ${appInfo.version}');

      final repo = ref.read(appUpdateRepositoryProvider);
      print('[CHECK_UPDATE] repo obtained: ${repo.runtimeType}');

      return repo
          .getLatestVersion()
          .match(
            (err) {
              print('[CHECK_UPDATE] API ERROR: $err');
              return state = AppUpdateState.error(err);
            },
            (remote) {
              try {
                print('[CHECK_UPDATE] API SUCCESS: version=${remote.version}, forceUpdate=${remote.isForceUpdate}, url=${remote.url}, content=${remote.updateContent}');
                if (remote.version.isEmpty) {
                  print('[CHECK_UPDATE] remote version is empty, no update');
                   return state = const AppUpdateState.notAvailable();
                }
                final latestVersion = Version.parse(remote.version);
                final currentVersion = Version.parse(appInfo.version);
                print('[CHECK_UPDATE] parsed: latest=$latestVersion, current=$currentVersion, isNewer=${latestVersion > currentVersion}');
                
                if (latestVersion > currentVersion) {
                  if (!remote.isForceUpdate && remote.version == _ignoreReleasePref.read()) {
                    print('[CHECK_UPDATE] version was previously ignored');
                    return state = AppUpdateStateIgnored(remote);
                  }
                  print('[CHECK_UPDATE] >>> NEW VERSION AVAILABLE! returning available state');
                  return state = AppUpdateState.available(remote);
                }
                print('[CHECK_UPDATE] already on latest version');
                return state = const AppUpdateState.notAvailable();
              } catch (error, stackTrace) {
                print('[CHECK_UPDATE] version parse error: $error');
                return state = AppUpdateState.error(AppUpdateFailure.unexpected(error, stackTrace));
              }
            },
          )
          .run();
    } catch (e, st) {
      print('[CHECK_UPDATE] FATAL CRASH: $e');
      print('[CHECK_UPDATE] stack: $st');
      return state = const AppUpdateState.initial();
    }
  }

  Future<void> ignoreRelease(RemoteVersionEntity version) async {
    loggy.debug("ignoring release [${version.version}]");
    await _ignoreReleasePref.write(version.version);
    state = AppUpdateStateIgnored(version);
  }
}
