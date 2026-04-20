import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/core/router/go_router/go_router_notifier.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:uuid/uuid.dart';
import 'package:hiddify/features/auth/data/auth_data_providers.dart';
import 'package:hiddify/features/auth/data/auth_repository.dart';
import 'package:hiddify/features/auth/model/auth_state.dart';
import 'package:hiddify/features/auth/model/user_model.dart';
import 'package:hiddify/features/profile/data/profile_data_providers.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_notifier.g.dart';

/// Keys for persisting auth data in SharedPreferences.
const _kAuthToken = 'xlink_auth_token';
const _kUserEmail = 'xlink_user_email';
const _kSessionId = 'xlink_session_id';

@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier with AppLogger {
  late AuthRepository _authRepo;
  DateTime? _lastCheckTime;

  @override
  AuthState build() {
    _authRepo = ref.watch(authRepositoryProvider);

    // Try to restore from persisted token.
    final prefs = ref.read(sharedPreferencesProvider).valueOrNull;
    if (prefs != null) {
      final token = prefs.getString(_kAuthToken);
      final email = prefs.getString(_kUserEmail);
      if (token != null && token.isNotEmpty && email != null) {
        _authRepo.setAuthToken(token);
        // Return authenticated with minimal info; then async-refresh
        // subscription details in the background.
        Future.microtask(() => checkSubscriptionStatus());
        return AuthState.authenticated(
          user: UserModel(email: email),
          authToken: token,
        );
      }
    }
    // If not authenticated, clear profiles
    Future.microtask(() => _clearAllProfiles());
    return const AuthState.unauthenticated();
  }

  Future<void> _clearAllProfiles() async {
    try {
      final profileRepo = await ref.read(profileRepositoryProvider.future);
      await profileRepo.deleteAll().run();
    } catch (e) {
      loggy.error('Failed to clear profiles', e);
    }
  }

  /// Force disconnect VPN when subscription state requires it.
  Future<void> _forceDisconnect() async {
    try {
      final connectionNotifier = ref.read(connectionNotifierProvider.notifier);
      await connectionNotifier.abortConnection();
      loggy.info('Force disconnected VPN due to subscription state change');
    } catch (e) {
      loggy.error('Failed to force disconnect VPN', e);
    }
  }

  Future<Map<String, dynamic>> _getDeviceInfo() async {
    final prefs = ref.read(sharedPreferencesProvider).requireValue;
    String? deviceId = prefs.getString('app_device_id');
    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await prefs.setString('app_device_id', deviceId);
    }
    String deviceName = Platform.localHostname;
    try {
      final deviceInfoPlugin = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        deviceName = '${androidInfo.brand} ${androidInfo.model}'.trim();
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        deviceName = iosInfo.name;
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfoPlugin.windowsInfo;
        deviceName = windowsInfo.computerName;
      } else if (Platform.isMacOS) {
        final macOsInfo = await deviceInfoPlugin.macOsInfo;
        deviceName = macOsInfo.computerName;
      } else if (Platform.isLinux) {
        final linuxInfo = await deviceInfoPlugin.linuxInfo;
        deviceName = linuxInfo.prettyName;
      }
    } catch (_) {}

    if (deviceName.isEmpty || deviceName == 'localhost') {
      deviceName = '${Platform.operatingSystem} device';
    }

    return {
      'is_app': true,
      'device_id': deviceId,
      'device_name': deviceName,
      'device_type': Platform.operatingSystem,
    };
  }

  /// Login with email and password.
  Future<void> login(String email, String password) async {
    state = const AuthState.loading();
    try {
      final deviceInfo = await _getDeviceInfo();
      final result = await _authRepo.login(
        email: email,
        password: password,
        deviceInfo: deviceInfo,
      );
      await _persistAuth(result.token, result.user.email);
      await _persistSessionId(result.sessionId);
      state = AuthState.authenticated(
        user: result.user,
        authToken: result.token,
      );

      // Auto-sync subscription after login.
      await checkSubscriptionStatus(force: true);
      await _syncNodes(result.token);
    } on AuthException catch (e) {
      state = AuthState.error(message: e.message);
    } catch (e, st) {
      loggy.error('Unexpected login error', e, st);
      state = AuthState.error(message: '登录失败: $e');
    }
  }

  /// Register a new account.
  Future<void> register(
    String email,
    String password, {
    String? inviteCode,
    String? emailCode,
  }) async {
    state = const AuthState.loading();
    try {
      final deviceInfo = await _getDeviceInfo();
      final result = await _authRepo.register(
        email: email,
        password: password,
        inviteCode: inviteCode,
        emailCode: emailCode,
        deviceInfo: deviceInfo,
      );
      await _persistAuth(result.token, result.user.email);
      await _persistSessionId(result.sessionId);
      state = AuthState.authenticated(
        user: result.user,
        authToken: result.token,
      );

      // Auto-sync subscription after registration.
      await checkSubscriptionStatus(force: true);
      await _syncNodes(result.token);
    } on AuthException catch (e) {
      state = AuthState.error(message: e.message);
    } catch (e, st) {
      loggy.error('Unexpected register error', e, st);
      state = AuthState.error(message: '注册失败: $e');
    }
  }

  /// Logout and clear persisted auth data.
  Future<void> logout() async {
    _authRepo.logout();
    final prefs = ref.read(sharedPreferencesProvider).valueOrNull;
    if (prefs != null) {
      await prefs.remove(_kAuthToken);
      await prefs.remove(_kUserEmail);
      await prefs.remove(_kSessionId);
    }
    await _clearAllProfiles();
    state = const AuthState.unauthenticated();
  }

  /// Refresh user info from the API (used internally, prefer refreshFullProfile for UI).
  Future<void> refreshUserInfo() async {
    final current = state;
    if (current is! Authenticated) return;
    try {
      final updatedUser = await _authRepo.getUserInfo();
      state = AuthState.authenticated(
        user: updatedUser,
        authToken: current.authToken,
      );
    } on AuthException catch (e) {
      loggy.warning('Failed to refresh user info: ${e.message}');
      await _handleAuthException(e);
    }
  }

  /// Fetch subscribe URL and import profile into Hiddify's profile system.
  Future<void> _syncNodes(String token) async {
    try {
      final subscribeUrl = await _authRepo.getSubscribeUrl();
      if (subscribeUrl.isNotEmpty) {
        loggy.info('Syncing nodes from: $subscribeUrl');
        final profileRepo = await ref.read(profileRepositoryProvider.future);
        await profileRepo
            .upsertRemote(subscribeUrl)
            .run()
            .then((result) => result.fold(
                  (failure) => loggy.error('Failed to sync nodes: $failure'),
                  (_) => loggy.info('Nodes synced successfully'),
                ));
      }
    } catch (e, st) {
      loggy.error('Failed to sync nodes', e, st);
      if (e is AuthException) {
        await _handleAuthException(e);
      }
    }
  }

  /// Force sync nodes from UI (home page sync button).
  /// Always checks status AND syncs nodes regardless of diff.
  Future<void> forceNodeSync() async {
    final current = state;
    if (current is! Authenticated) return;

    await checkSubscriptionStatus(force: true);
    await _syncNodes(current.authToken);
  }

  /// Full profile refresh (personal center refresh button).
  /// Fetches complete user info (including balance) + checks subscription status.
  Future<void> refreshFullProfile() async {
    final current = state;
    if (current is! Authenticated) return;
    try {
      final updatedUser = await _authRepo.getUserInfo();
      state = AuthState.authenticated(
        user: updatedUser,
        authToken: current.authToken,
      );
      await checkSubscriptionStatus(force: true);
    } on AuthException catch (e) {
      loggy.warning('Failed to refresh full profile: ${e.message}');
      await _handleAuthException(e);
    }
  }

  /// Unified entry point for checking subscription status.
  /// Calls getSubscribeInfo (1 API call), diffs against cached state,
  /// and conditionally triggers node sync / VPN disconnect / profile clearing.
  ///
  /// [force] bypasses 30-second deduplication.
  Future<void> checkSubscriptionStatus({bool force = false}) async {
    final current = state;
    if (current is! Authenticated) return;

    // 30-second deduplication
    if (!force && _lastCheckTime != null) {
      final elapsed = DateTime.now().difference(_lastCheckTime!);
      if (elapsed.inSeconds < 30) {
        loggy.debug('Skipping subscription check, last check was ${elapsed.inSeconds}s ago');
        return;
      }
    }
    _lastCheckTime = DateTime.now();

    try {
      final info = await _authRepo.getSubscribeInfo();

      // Extract new values
      final planMap = info['plan'] as Map<String, dynamic>?;
      final newPlanName = planMap?['name'] as String?;
      final newPlanId = info['plan_id'] as int?;
      final newSubscribeUrl = info['subscribe_url'] as String?;
      final newCanConnect = info['can_connect_vpn'] as bool? ?? true;
      final newU = info['u'] as int? ?? 0;
      final newD = info['d'] as int? ?? 0;
      final newTransferEnable = info['transfer_enable'] as int? ?? 0;
      final newExpiredAt = info['expired_at'] as int?;
      final newDeviceLimit = info['device_limit'] as int?;

      // Compute diff against current state
      final oldUser = current.user;
      final planChanged = oldUser.planId != newPlanId;
      final urlChanged = oldUser.subscribeUrl != newSubscribeUrl;
      final planRemoved = oldUser.planId != null && newPlanId == null;
      final planAdded = oldUser.planId == null && newPlanId != null;
      final connectBecameFalse = oldUser.canConnectVpn && !newCanConnect;
      final connectRestored = !oldUser.canConnectVpn && newCanConnect;
      final deviceLimitDecreased = oldUser.deviceLimit != null &&
          newDeviceLimit != null &&
          newDeviceLimit < oldUser.deviceLimit!;

      // Update state (triggers all UI reactivity)
      final updatedUser = current.user.copyWith(
        planId: newPlanId,
        planName: newPlanName,
        u: newU,
        d: newD,
        transferEnable: newTransferEnable,
        expiredAt: newExpiredAt,
        subscribeUrl: newSubscribeUrl,
        deviceLimit: newDeviceLimit,
        canConnectVpn: newCanConnect,
      );
      state = AuthState.authenticated(user: updatedUser, authToken: current.authToken);

      // Decision: clear profiles
      if (planRemoved) {
        loggy.info('Plan removed, clearing profiles and disconnecting');
        await _clearAllProfiles();
        await _forceDisconnect();
        return;
      }

      // Decision: force disconnect (device limit / traffic exceeded / banned)
      // Also covers device limit decrease — when limit shrinks and this device
      // is now over-limit, backend returns can_connect_vpn=false in the same response.
      if (connectBecameFalse) {
        loggy.info('can_connect_vpn became false, force disconnecting');
        await _forceDisconnect();
        return;
      }

      // Decision: device limit decreased but this device is still within limit
      // (can_connect_vpn is still true). Just log it — UI already updated above.
      if (deviceLimitDecreased && newCanConnect) {
        loggy.info('Device limit decreased from ${oldUser.deviceLimit} to $newDeviceLimit, '
            'but current device is still within limit');
      }

      // Decision: sync nodes (plan changed, URL changed, plan added, or connect restored with plan)
      final needsNodeSync = planChanged || urlChanged || planAdded ||
          (connectRestored && newPlanId != null);
      if (needsNodeSync) {
        loggy.info('Subscription changed (plan=$planChanged, url=$urlChanged, added=$planAdded, restored=$connectRestored), syncing nodes');
        await _syncNodes(current.authToken);
      }
    } on AuthException catch (e) {
      loggy.warning('Failed to check subscription status: ${e.message}');
      await _handleAuthException(e);
    }
  }

  Future<void> _persistAuth(String token, String email) async {
    final prefs = ref.read(sharedPreferencesProvider).valueOrNull;
    if (prefs != null) {
      await prefs.setString(_kAuthToken, token);
      await prefs.setString(_kUserEmail, email);
    }
  }

  Future<void> _persistSessionId(int? sessionId) async {
    final prefs = ref.read(sharedPreferencesProvider).valueOrNull;
    if (prefs != null && sessionId != null) {
      await prefs.setInt(_kSessionId, sessionId);
    }
  }

  /// Get the current device's session ID (for identifying "this device" in session list).
  int? get currentSessionId {
    final prefs = ref.read(sharedPreferencesProvider).valueOrNull;
    return prefs?.getInt(_kSessionId);
  }

  /// Handle auth exceptions to auto-logout on invalid/expired tokens
  Future<void> _handleAuthException(AuthException e) async {
    final msg = e.message;
    if (msg.contains('HTTP 401') ||
        msg.contains('HTTP 403') ||
        msg.contains('Unauthorized') ||
        msg.contains('未登录') ||
        msg.contains('过期')) {
      loggy.info('Token expired or invalid. Forcing logout...');
      await _forceDisconnect();
      await logout();

      final context = rootNavKey.currentContext;
      if (context != null && context.mounted) {
        final t = ref.read(translationsProvider).valueOrNull;
        if (t != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t.pages.xlink.loginExpiredHint),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }
}

/// Convenience provider: is the user currently logged in?
@Riverpod(keepAlive: true)
bool isAuthenticated(IsAuthenticatedRef ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState is Authenticated;
}
