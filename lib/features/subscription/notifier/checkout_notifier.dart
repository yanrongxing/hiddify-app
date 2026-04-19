import 'package:hiddify/features/subscription/data/subscription_data_providers.dart';
import 'package:hiddify/features/subscription/data/subscription_repository.dart';
import 'package:hiddify/features/subscription/model/billing_period.dart';
import 'package:hiddify/features/subscription/model/coupon_model.dart';
import 'package:hiddify/features/subscription/model/plan_model.dart';
import 'package:hiddify/features/subscription/notifier/shop_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'checkout_notifier.g.dart';

class CheckoutState {
  const CheckoutState({
    this.selectedPeriod,
    this.coupon,
    this.couponError,
    this.isSubmitting = false,
    this.plan,
  });

  final BillingPeriod? selectedPeriod;
  final CouponModel? coupon;
  final String? couponError;
  final bool isSubmitting;
  final PlanModel? plan;

  CheckoutState copyWith({
    BillingPeriod? selectedPeriod,
    CouponModel? coupon,
    String? couponError,
    bool? isSubmitting,
    PlanModel? plan,
    bool clearCoupon = false,
    bool clearCouponError = false,
  }) {
    return CheckoutState(
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      coupon: clearCoupon ? null : (coupon ?? this.coupon),
      couponError: clearCouponError ? null : (couponError ?? this.couponError),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      plan: plan ?? this.plan,
    );
  }
}

@riverpod
class CheckoutNotifier extends _$CheckoutNotifier {
  @override
  CheckoutState build(int planId) {
    final plansAsync = ref.watch(shopNotifierProvider);
    PlanModel? plan;
    BillingPeriod? initialPeriod;

    if (plansAsync.hasValue) {
      plan = plansAsync.value!.where((p) => p.id == planId).firstOrNull;
      if (plan != null) {
        for (final p in BillingPeriod.values) {
          if (p.priceFrom(plan) != null) {
            initialPeriod = p;
            break;
          }
        }
      }
    }

    return CheckoutState(plan: plan, selectedPeriod: initialPeriod);
  }

  void selectPeriod(BillingPeriod period) {
    state = state.copyWith(selectedPeriod: period, clearCoupon: true, clearCouponError: true);
  }

  Future<void> applyCoupon(String code) async {
    if (state.plan == null || state.selectedPeriod == null) return;
    state = state.copyWith(clearCouponError: true);
    
    try {
      final repo = ref.read(subscriptionRepositoryProvider);
      final coupon = await repo.checkCoupon(code, state.plan!.id, state.selectedPeriod!.apiKey);
      state = state.copyWith(coupon: coupon);
    } on SubscriptionException catch (e) {
      state = state.copyWith(couponError: e.message, clearCoupon: true);
    } catch (e) {
      state = state.copyWith(couponError: '验证失败', clearCoupon: true);
    }
  }

  void clearCoupon() {
    state = state.copyWith(clearCoupon: true, clearCouponError: true);
  }

  /// Submit the order. Returns the trade_no on success, throws exception on failure.
  Future<String> submitOrder({String? couponCode}) async {
    if (state.plan == null || state.selectedPeriod == null) {
      throw SubscriptionException('信息不完整，无法下单');
    }
    
    state = state.copyWith(isSubmitting: true);
    try {
      final repo = ref.read(subscriptionRepositoryProvider);
      
      // 1. Fetch pending orders
      final pendingOrders = await repo.fetchOrders(status: 0);
      
      // 2. Cancel pending orders
      for (final order in pendingOrders) {
        await repo.cancelOrder(order.tradeNo);
      }
      
      // 3. Create new order
      final tradeNo = await repo.createOrder(
        state.plan!.id,
        state.selectedPeriod!.apiKey,
        couponCode: couponCode,
      );
      
      return tradeNo;
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }
}
