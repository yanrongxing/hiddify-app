import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/features/subscription/model/plan_model.dart';

class PlanCard extends StatelessWidget {
  const PlanCard({
    super.key,
    required this.plan,
    required this.onPurchase,
  });

  final PlanModel plan;
  final VoidCallback onPurchase;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lowestPrice = plan.lowestPrice;
    
    final displayPrice = lowestPrice != null 
        ? '¥${(lowestPrice / 100).toStringAsFixed(2)}/起' 
        : '免费';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    plan.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  displayPrice,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Gap(16),
            _buildFeatureRow(
              context, 
              Icons.data_usage_rounded, 
              plan.transferEnable != null ? '${plan.transferEnable} GB 流量' : '不限流量'
            ),
            const Gap(8),
            _buildFeatureRow(
              context, 
              Icons.speed_rounded, 
              plan.speedLimit != null ? '最高 ${plan.speedLimit} Mbps' : '不限速'
            ),
            const Gap(8),
            _buildFeatureRow(
              context, 
              Icons.devices_rounded, 
              plan.deviceLimit != null ? '最多 ${plan.deviceLimit} 台设备' : '不限设备'
            ),
            const Gap(24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onPurchase,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('立即购买', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const Gap(12),
        Text(
          text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
