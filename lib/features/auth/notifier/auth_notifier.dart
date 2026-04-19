import 'package:hiddify/core/preferences/preferences_provider.dart';
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

@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier with AppLogger {
  late AuthRepository _authRepo;

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
        // full subscription details in the background.
        Future.microtask(() => refreshSubscribeInfo());
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

  /// Login with email and password.
  Future<void> login(String email, String password) async {
    state = const AuthState.loading();
    try {
      final result = await _authRepo.login(
        email: email,
        password: password,
      );
      await _persistAuth(result.token, result.user.email);
      state = AuthState.authenticated(
        user: result.user,
        authToken: result.token,
      );

      // Auto-sync subscription after login.
      await _syncSubscription(result.token);
      await refreshSubscribeInfo();
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
      final result = await _authRepo.register(
        email: email,
        password: password,
        inviteCode: inviteCode,
        emailCode: emailCode,
      );
      await _persistAuth(result.token, result.user.email);
      state = AuthState.authenticated(
        user: result.user,
        authToken: result.token,
      );

      // Auto-sync subscription after registration.
      await _syncSubscription(result.token);
      await refreshSubscribeInfo();
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
    }
    await _clearAllProfiles();
    state = const AuthState.unauthenticated();
  }

  /// Refresh user info from the API.
  Future<void> refreshUserInfo() async {
    final current = state;
    if (current is! Authenticated) return;
    try {
      final updatedUser = await _authRepo.getUserInfo();
      state = AuthState.authenticated(
        user: updatedUser,
        authToken: current.authToken,
      );
      await refreshSubscribeInfo();
    } on AuthException catch (e) {
      loggy.warning('Failed to refresh user info: ${e.message}');
      // If 401, force logout
      if (e.message.contains('401') || e.message.contains('Unauthorized')) {
        await logout();
      }
    }
  }

  /// Sync subscription from Xboard and import into Hiddify's profile system.
  Future<void> _syncSubscription(String token) async {
    try {
      final subscribeUrl = await _authRepo.getSubscribeUrl();
      if (subscribeUrl.isNotEmpty) {
        loggy.info('Auto-syncing subscription: $subscribeUrl');
        final profileRepo =
            await ref.read(profileRepositoryProvider.future);
        await profileRepo
            .upsertRemote(subscribeUrl)
            .run()
            .then((result) => result.fold(
                  (failure) => loggy.error(
                      'Failed to sync subscription profile: $failure'),
                  (_) => loggy.info('Subscription profile synced successfully'),
                ));
      }
    } catch (e, st) {
      loggy.error('Failed to sync subscription', e, st);
    }
  }

  /// Manually trigger subscription sync (e.g. from UI refresh button).
  Future<void> syncSubscription() async {
    final current = state;
    if (current is! Authenticated) return;

    // Refresh user info and subscription info
    await refreshUserInfo();
    await _syncSubscription(current.authToken);
  }

  /// Fetch subscription details and update UserModel.
  Future<void> refreshSubscribeInfo() async {
    final current = state;
    if (current is! Authenticated) return;
    try {
      final info = await _authRepo.getSubscribeInfo();
      // Extract plan name from nested plan object if available
      final planMap = info['plan'] as Map<String, dynamic>?;
      final planName = planMap?['name'] as String?;
      final updatedUser = current.user.copyWith(
        planId: info['plan_id'] as int?,
        planName: planName,
        u: info['u'] as int? ?? 0,
        d: info['d'] as int? ?? 0,
        transferEnable: info['transfer_enable'] as int? ?? 0,
        expiredAt: info['expired_at'] as int?,
        subscribeUrl: info['subscribe_url'] as String?,
      );
      state = AuthState.authenticated(user: updatedUser, authToken: current.authToken);
    } on AuthException catch (e) {
      loggy.warning('Failed to refresh subscribe info: ${e.message}');
    }
  }

  Future<void> _persistAuth(String token, String email) async {
    final prefs = ref.read(sharedPreferencesProvider).valueOrNull;
    if (prefs != null) {
      await prefs.setString(_kAuthToken, token);
      await prefs.setString(_kUserEmail, email);
    }
  }
}

/// Convenience provider: is the user currently logged in?
@Riverpod(keepAlive: true)
bool isAuthenticated(IsAuthenticatedRef ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState is Authenticated;
}
