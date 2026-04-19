import 'package:hiddify/features/subscription/model/plan_model.dart';

/// Defines the available billing periods for subscription plans.
enum BillingPeriod {
  monthPrice('month_price', '月付', 1),
  quarterPrice('quarter_price', '季付', 3),
  halfYearPrice('half_year_price', '半年付', 6),
  yearPrice('year_price', '年付', 12),
  twoYearPrice('two_year_price', '两年付', 24),
  threeYearPrice('three_year_price', '三年付', 36),
  onetimePrice('onetime_price', '一次性', 0);

  const BillingPeriod(this.apiKey, this.label, this.months);

  /// Key used in API requests and PlanModel fields.
  final String apiKey;

  /// Display label.
  final String label;

  /// Number of months for calculation.
  final int months;

  /// Extracts the price for this period from a given plan.
  int? priceFrom(PlanModel plan) => switch (this) {
        monthPrice => plan.monthPrice,
        quarterPrice => plan.quarterPrice,
        halfYearPrice => plan.halfYearPrice,
        yearPrice => plan.yearPrice,
        twoYearPrice => plan.twoYearPrice,
        threeYearPrice => plan.threeYearPrice,
        onetimePrice => plan.onetimePrice,
      };

  /// Calculates the savings percentage compared to the monthly price.
  int savingsPercent(PlanModel plan) {
    if (months <= 1 || plan.monthPrice == null || plan.monthPrice == 0) {
      return 0;
    }
    final price = priceFrom(plan);
    if (price == null) return 0;
    final monthlyEquiv = price / months;
    return ((1 - monthlyEquiv / plan.monthPrice!) * 100).round();
  }
}
