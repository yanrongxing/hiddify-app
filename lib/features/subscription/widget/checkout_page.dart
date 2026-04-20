import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/subscription/model/billing_period.dart';
import 'package:hiddify/features/subscription/notifier/checkout_notifier.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class CheckoutPage extends HookConsumerWidget {
  const CheckoutPage({super.key, required this.planId});

  final String planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = ref.watch(translationsProvider).requireValue;
    final id = int.tryParse(planId) ?? 0;
    final checkoutState = ref.watch(checkoutNotifierProvider(id));
    final notifier = ref.read(checkoutNotifierProvider(id).notifier);
    final couponController = useTextEditingController();

    if (checkoutState.plan == null) {
      return Scaffold(
        appBar: AppBar(title: Text(t.pages.xlink.confirmOrder)),
        body: Center(child: Text(t.pages.xlink.planNotFound)),
      );
    }

    final plan = checkoutState.plan!;
    final periods = BillingPeriod.values.where((p) => p.priceFrom(plan) != null).toList();

    int getSubtotal() {
      if (checkoutState.selectedPeriod == null) return 0;
      return checkoutState.selectedPeriod!.priceFrom(plan) ?? 0;
    }

    int getDiscount() {
      if (checkoutState.coupon == null) return 0;
      return checkoutState.coupon!.discountFor(getSubtotal());
    }

    final subtotal = getSubtotal();
    final discount = getDiscount();
    final total = (subtotal - discount).clamp(0, double.infinity).toInt();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.pages.xlink.confirmOrder,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // Plan info card
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
                    plan.name,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Gap(16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _Stat(label: t.pages.xlink.traffic, value: plan.transferEnable != null ? '${plan.transferEnable} GB' : t.pages.xlink.unlimited),
                      _Stat(label: t.pages.xlink.speed, value: plan.speedLimit != null ? '${plan.speedLimit} Mbps' : t.pages.xlink.unlimitedSpeed),
                      _Stat(label: t.pages.xlink.devices, value: plan.deviceLimit != null ? '${plan.deviceLimit}' : t.pages.xlink.unlimited),
                    ],
                  ),
                  if (plan.content != null && plan.content!.isNotEmpty) ...[
                    const Gap(16),
                    const Divider(),
                    const Gap(8),
                    Text(
                      plan.content!,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const Gap(24),

          // Period selection
          Text(
            t.pages.xlink.selectPeriod,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Gap(12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: periods.map((period) {
              final isSelected = checkoutState.selectedPeriod == period;
              final price = period.priceFrom(plan)!;
              final savings = period.savingsPercent(plan);
              
              return InkWell(
                onTap: () => notifier.selectPeriod(period),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: (MediaQuery.of(context).size.width - 32 - 12) / 2,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                      width: isSelected ? 2 : 1,
                    ),
                    color: isSelected ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3) : Colors.transparent,
                  ),
                  child: Column(
                    children: [
                      Text(
                        period.label,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: isSelected ? theme.colorScheme.primary : null,
                          fontWeight: isSelected ? FontWeight.bold : null,
                        ),
                      ),
                      const Gap(8),
                      Text(
                        '¥${(price / 100).toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: isSelected ? theme.colorScheme.primary : null,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (savings > 0) ...[
                        const Gap(4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            t.pages.xlink.savingsPercent(percent: savings.toString()),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onErrorContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ] else const Gap(20), // Placeholder to keep height consistent
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const Gap(24),

          // Coupon
          Text(
            t.pages.xlink.coupon,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Gap(12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: couponController,
                  decoration: InputDecoration(
                    hintText: t.pages.xlink.enterCouponCode,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
              const Gap(12),
              FilledButton.tonal(
                onPressed: () {
                  if (couponController.text.isNotEmpty) {
                    notifier.applyCoupon(couponController.text);
                  }
                },
                child: Text(t.pages.xlink.verify),
              ),
            ],
          ),
          if (checkoutState.couponError != null) ...[
            const Gap(8),
            Text(
              checkoutState.couponError!,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
            ),
          ],
          if (checkoutState.coupon != null) ...[
            const Gap(8),
            Row(
              children: [
                Icon(Icons.check_circle_rounded, size: 16, color: theme.colorScheme.primary),
                const Gap(8),
                Text(
                  '${t.pages.xlink.applied}: -¥${(discount / 100).toStringAsFixed(2)}',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    couponController.clear();
                    notifier.clearCoupon();
                  },
                  child: Text(t.pages.xlink.clear),
                ),
              ],
            ),
          ],
          const Gap(32),

          // Summary
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(t.pages.xlink.planFee, style: theme.textTheme.bodyLarge),
                    Text('¥${(subtotal / 100).toStringAsFixed(2)}', style: theme.textTheme.bodyLarge),
                  ],
                ),
                if (discount > 0) ...[
                  const Gap(8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(t.pages.xlink.couponDiscount, style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.primary)),
                      Text('-¥${(discount / 100).toStringAsFixed(2)}', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.primary)),
                    ],
                  ),
                ],
                const Gap(16),
                const Divider(),
                const Gap(16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(t.pages.xlink.orderTotal, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    Text(
                      '¥${(total / 100).toStringAsFixed(2)}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Gap(24),

          // Submit
          FilledButton(
            onPressed: checkoutState.isSubmitting ? null : () async {
              try {
                final tradeNo = await notifier.submitOrder(
                  couponCode: checkoutState.coupon != null ? couponController.text : null,
                );
                if (context.mounted) {
                  context.pushNamed('orderDetail', pathParameters: {'tradeNo': tradeNo});
                }
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
            child: checkoutState.isSubmitting
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    t.pages.xlink.placeOrder,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
          const Gap(32),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const Gap(4),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
