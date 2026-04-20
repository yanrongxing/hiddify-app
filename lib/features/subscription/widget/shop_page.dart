import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/auth/notifier/auth_notifier.dart';
import 'package:hiddify/features/subscription/notifier/shop_notifier.dart';
import 'package:hiddify/features/subscription/widget/plan_card.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ShopPage extends HookConsumerWidget {
  const ShopPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = ref.watch(translationsProvider).requireValue;
    final plansAsync = ref.watch(shopNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.pages.xlink.subscriptionShop,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: plansAsync.when(
        data: (plans) {
          if (plans.isEmpty) {
            return Center(
              child: Text(
                t.pages.xlink.noPlansAvailable,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 16),
            itemCount: plans.length,
            itemBuilder: (context, index) {
              final plan = plans[index];
              return PlanCard(
                plan: plan,
                onPurchase: () {
                  final isAuthenticated = ref.read(isAuthenticatedProvider);
                  if (isAuthenticated) {
                    context.pushNamed('checkout', pathParameters: {'planId': plan.id.toString()});
                  } else {
                    context.push('/login');
                  }
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(t.pages.xlink.loadFailed, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                err.toString(),
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.read(shopNotifierProvider.notifier).refresh(),
                child: Text(t.pages.xlink.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
