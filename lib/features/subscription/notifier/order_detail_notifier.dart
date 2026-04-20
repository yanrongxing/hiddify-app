import 'dart:async';
import 'package:hiddify/features/auth/notifier/auth_notifier.dart';
import 'package:hiddify/features/subscription/data/subscription_data_providers.dart';
import 'package:hiddify/features/subscription/model/order_model.dart';
import 'package:hiddify/features/subscription/model/payment_method_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:url_launcher/url_launcher.dart';

part 'order_detail_notifier.g.dart';

class OrderDetailState {
  const OrderDetailState({
    this.order,
    this.paymentMethods = const [],
    this.selectedMethodId,
    this.isCheckingOut = false,
    this.pollStatus = 'idle',
  });

  final OrderModel? order;
  final List<PaymentMethodModel> paymentMethods;
  final int? selectedMethodId;
  final bool isCheckingOut;
  final String pollStatus;

  OrderDetailState copyWith({
    OrderModel? order,
    List<PaymentMethodModel>? paymentMethods,
    int? selectedMethodId,
    bool? isCheckingOut,
    String? pollStatus,
  }) {
    return OrderDetailState(
      order: order ?? this.order,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      selectedMethodId: selectedMethodId ?? this.selectedMethodId,
      isCheckingOut: isCheckingOut ?? this.isCheckingOut,
      pollStatus: pollStatus ?? this.pollStatus,
    );
  }
}

@riverpod
class OrderDetailNotifier extends _$OrderDetailNotifier {
  Timer? _pollingTimer;

  @override
  Future<OrderDetailState> build(String tradeNo) async {
    ref.onDispose(() {
      _pollingTimer?.cancel();
    });

    final repo = ref.watch(subscriptionRepositoryProvider);
    final order = await repo.getOrderDetail(tradeNo);
    
    // Auto complete if already paid/offset
    if (order.status != 0 && order.status != 1) {
      return OrderDetailState(order: order, pollStatus: 'success');
    }

    final methods = await repo.getPaymentMethods();
    final selectedId = methods.isNotEmpty ? methods.first.id : null;

    return OrderDetailState(
      order: order,
      paymentMethods: methods,
      selectedMethodId: selectedId,
    );
  }

  void selectPaymentMethod(int id) {
    if (state.hasValue) {
      state = AsyncData(state.value!.copyWith(selectedMethodId: id));
    }
  }

  Future<void> checkout() async {
    final currentState = state.valueOrNull;
    if (currentState == null || currentState.order == null || currentState.selectedMethodId == null) return;

    state = AsyncData(currentState.copyWith(isCheckingOut: true));
    try {
      final repo = ref.read(subscriptionRepositoryProvider);
      final result = await repo.checkout(currentState.order!.tradeNo, currentState.selectedMethodId!);

      final type = result['type'];
      final data = result['data'];

      if (type == -1) {
        // Offset / direct success
        state = AsyncData(currentState.copyWith(isCheckingOut: false, pollStatus: 'success'));
        _onPaymentSuccess();
      } else if ((type == 0 || type == 1) && data is String) {
        // type=0: redirect URL, type=1: payment counter page URL
        // Both are handled the same way: open in external browser.
        final url = Uri.parse(data);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
          state = AsyncData(currentState.copyWith(isCheckingOut: false, pollStatus: 'polling'));
          _startPolling(currentState.order!.tradeNo);
        } else {
          throw Exception('无法打开支付链接');
        }
      } else {
        throw Exception('未知的支付返回类型: type=$type');
      }
    } catch (e, st) {
      state = AsyncData(currentState.copyWith(isCheckingOut: false));
      state = AsyncError(e, st); // Will show error in UI
    }
  }

  void _startPolling(String tradeNo) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      try {
        final repo = ref.read(subscriptionRepositoryProvider);
        final status = await repo.checkOrderStatus(tradeNo);
        
        if (status != 0 && status != 1) {
          timer.cancel();
          if (state.hasValue) {
            state = AsyncData(state.value!.copyWith(pollStatus: 'success'));
          }
          _onPaymentSuccess();
        }
      } catch (e) {
        // Ignore polling errors, just retry
      }
    });
  }

  void _onPaymentSuccess() {
    // Check subscription status — diff will detect plan change and auto-sync nodes
    ref.read(authNotifierProvider.notifier).checkSubscriptionStatus(force: true);
  }
}
