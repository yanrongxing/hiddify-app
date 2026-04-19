import 'package:hiddify/features/auth/data/auth_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_data_providers.g.dart';

/// TODO: Replace with your actual Xboard backend URL.
const _xboardBaseUrl = 'https://47.79.38.161';

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return AuthRepository(baseUrl: _xboardBaseUrl);
}

/// Site configuration provider — fetches is_email_verify, is_invite_force, etc.
@riverpod
Future<Map<String, dynamic>> siteConfig(Ref ref) async {
  final repo = ref.read(authRepositoryProvider);
  return repo.getSiteConfig();
}
