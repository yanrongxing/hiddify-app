import 'package:hiddify/features/subscription/data/subscription_data_providers.dart';
import 'package:hiddify/features/subscription/model/plan_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'shop_notifier.g.dart';

@riverpod
class ShopNotifier extends _$ShopNotifier {
  @override
  Future<List<PlanModel>> build() async {
    final repo = ref.watch(subscriptionRepositoryProvider);
    return repo.fetchPlans();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(subscriptionRepositoryProvider);
      return repo.fetchPlans();
    });
  }
}
