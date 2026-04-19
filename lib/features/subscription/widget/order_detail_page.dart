import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/features/subscription/notifier/order_detail_notifier.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class OrderDetailPage extends HookConsumerWidget {
  const OrderDetailPage({super.key, required this.tradeNo});

  final String tradeNo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final orderStateAsync = ref.watch(orderDetailNotifierProvider(tradeNo));
    final notifier = ref.read(orderDetailNotifierProvider(tradeNo).notifier);

    // Watch for success status to navigate automatically
    ref.listen(orderDetailNotifierProvider(tradeNo), (previous, next) {
      if (next.valueOrNull?.pollStatus == 'success') {
        Future.delayed(const Duration(seconds: 3), () {
          if (context.mounted) {
            context.go('/');
          }
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "订单支付",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: orderStateAsync.when(
        data: (state) {
          final order = state.order;
          if (order == null) {
            return const Center(child: Text('订单不存在'));
          }

          if (state.pollStatus == 'success') {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded, size: 80, color: theme.colorScheme.primary),
                  const Gap(24),
                  Text(
                    '支付成功！',
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Gap(8),
                  Text(
                    '正在同步订阅信息并返回首页...',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              // Order summary card
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.15),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '订单金额',
                        style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                      const Gap(8),
                      Text(
                        '¥${order.totalDisplay}',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Gap(16),
                      const Divider(),
                      const Gap(16),
                      _InfoRow(label: '套餐', value: order.plan?.name ?? '未知套餐'),
                      const Gap(12),
                      _InfoRow(label: '订单号', value: order.tradeNo, mono: true),
                      const Gap(12),
                      _InfoRow(label: '状态', value: order.statusText),
                    ],
                  ),
                ),
              ),
              const Gap(24),

              // Payment methods
              if (state.pollStatus == 'idle') ...[
                Text(
                  '选择支付方式',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Gap(12),
                Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: state.paymentMethods.map((method) {
                      return RadioListTile<int>(
                        title: Text(method.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        value: method.id,
                        groupValue: state.selectedMethodId,
                        onChanged: (id) {
                          if (id != null) {
                            notifier.selectPaymentMethod(id);
                          }
                        },
                      );
                    }).toList(),
                  ),
                ),
                const Gap(32),

                // Checkout button
                FilledButton(
                  onPressed: state.isCheckingOut ? null : () async {
                    try {
                      await notifier.checkout();
                    } catch (e) {
                      if (context.mounted) {
                        CustomToast.error(e.toString()).show(context);
                      }
                    }
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: state.isCheckingOut
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          '确认支付',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ] else if (state.pollStatus == 'polling') ...[
                Container(
                  padding: const EdgeInsets.all(32),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      const Gap(16),
                      Text(
                        '等待支付确认...',
                        style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary),
                      ),
                      const Gap(8),
                      Text(
                        '请在外部浏览器完成支付，支付成功后此页面会自动更新',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
              const Gap(16),
              Text('加载失败', style: theme.textTheme.titleMedium),
              const Gap(8),
              Text(err.toString(), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.mono = false,
  });

  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: mono ? 'monospace' : null,
          ),
        ),
      ],
    );
  }
}
