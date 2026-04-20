import 'package:hiddify/features/auth/data/auth_data_providers.dart';
import 'package:hiddify/features/auth/data/auth_repository.dart';
import 'package:hiddify/features/auth/model/session_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'session_notifier.g.dart';

@riverpod
class SessionNotifier extends _$SessionNotifier {
  late AuthRepository _authRepo;

  @override
  Future<List<SessionModel>> build() {
    _authRepo = ref.watch(authRepositoryProvider);
    return _fetch();
  }

  Future<List<SessionModel>> _fetch() async {
    try {
      return await _authRepo.getActiveSessions();
    } on AuthException {
      return [];
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _fetch());
  }

  Future<bool> removeSession(int sessionId) async {
    try {
      final result = await _authRepo.removeActiveSession(sessionId);
      if (result) await refresh();
      return result;
    } on AuthException {
      return false;
    }
  }

  /// Get only non-web (app) sessions.
  List<SessionModel> get appSessions =>
      (state.valueOrNull ?? []).where((s) => !s.isWeb).toList();

  /// Count of non-web active device sessions.
  int get appDeviceCount => appSessions.length;
}
