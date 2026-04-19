import 'package:hiddify/features/auth/data/auth_data_providers.dart';
import 'package:hiddify/features/subscription/data/subscription_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'subscription_data_providers.g.dart';

@Riverpod(keepAlive: true)
SubscriptionRepository subscriptionRepository(Ref ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return SubscriptionRepository(dio: authRepo.dio);
}
