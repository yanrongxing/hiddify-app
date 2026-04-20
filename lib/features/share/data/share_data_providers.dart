import 'package:hiddify/features/auth/data/auth_data_providers.dart';
import 'package:hiddify/features/share/data/share_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'share_data_providers.g.dart';

@Riverpod(keepAlive: true)
ShareRepository shareRepository(Ref ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return ShareRepository(dio: authRepo.dio);
}
