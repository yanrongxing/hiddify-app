import 'package:hiddify/features/app_update/data/app_update_repository.dart';
import 'package:hiddify/features/auth/data/auth_data_providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_update_data_providers.g.dart';

@Riverpod(keepAlive: true)
AppUpdateRepository appUpdateRepository(Ref ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return AppUpdateRepositoryImpl(dio: authRepo.dio);
}
