# Subscription Plan Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement native subscription plan purchase flow in Hiddify Flutter app, referencing xboard-user-custom's Shop→Checkout→OrderDetail flow.

**Architecture:** New `lib/features/subscription/` feature module with data/model/notifier/widget layers following existing Riverpod+freezed patterns. Reuses AuthRepository's Dio instance for API calls. Three pages registered in GoRouter under settings branch.

**Tech Stack:** Flutter, Riverpod, freezed, json_serializable, url_launcher, Dio

**Spec:** `docs/superpowers/specs/2026-04-20-subscription-plan-design.md`

---

### Task 1: Data Models (freezed)

**Files:**
- Create: `lib/features/subscription/model/plan_model.dart`
- Create: `lib/features/subscription/model/plan_model.freezed.dart` (generated)
- Create: `lib/features/subscription/model/plan_model.g.dart` (generated)
- Create: `lib/features/subscription/model/order_model.dart`
- Create: `lib/features/subscription/model/order_model.freezed.dart` (generated)
- Create: `lib/features/subscription/model/order_model.g.dart` (generated)
- Create: `lib/features/subscription/model/coupon_model.dart`
- Create: `lib/features/subscription/model/coupon_model.freezed.dart` (generated)
- Create: `lib/features/subscription/model/coupon_model.g.dart` (generated)
- Create: `lib/features/subscription/model/payment_method_model.dart`
- Create: `lib/features/subscription/model/payment_method_model.freezed.dart` (generated)
- Create: `lib/features/subscription/model/payment_method_model.g.dart` (generated)
- Create: `lib/features/subscription/model/subscribe_info_model.dart`
- Create: `lib/features/subscription/model/subscribe_info_model.freezed.dart` (generated)
- Create: `lib/features/subscription/model/subscribe_info_model.g.dart` (generated)
- Create: `lib/features/subscription/model/billing_period.dart`

- [ ] **Step 1: Create PlanModel**

Create `lib/features/subscription/model/plan_model.dart` with freezed class containing: `id` (int, required), `name` (String, required), `content` (String?), `transferEnable` (int?, JsonKey 'transfer_enable'), `speedLimit` (int?, JsonKey 'speed_limit'), `deviceLimit` (int?, JsonKey 'device_limit'), `monthPrice` (int?, JsonKey 'month_price'), `quarterPrice` (int?, JsonKey 'quarter_price'), `halfYearPrice` (int?, JsonKey 'half_year_price'), `yearPrice` (int?, JsonKey 'year_price'), `twoYearPrice` (int?, JsonKey 'two_year_price'), `threeYearPrice` (int?, JsonKey 'three_year_price'), `onetimePrice` (int?, JsonKey 'onetime_price'). Include `fromJson` factory. See spec §4 for exact definition.

- [ ] **Step 2: Create OrderModel**

Create `lib/features/subscription/model/order_model.dart` with freezed class containing: `tradeNo` (String, required, JsonKey 'trade_no'), `status` (int, required), `totalAmount` (int, required, JsonKey 'total_amount'), `discountAmount` (int, Default(0), JsonKey 'discount_amount'), `handlingAmount` (int, Default(0), JsonKey 'handling_amount'), `period` (String?), `plan` (PlanModel?), `createdAt` (int?, JsonKey 'created_at'). Include `fromJson` factory. See spec §4.

- [ ] **Step 3: Create CouponModel**

Create `lib/features/subscription/model/coupon_model.dart` with freezed class containing: `type` (int, required — 1=fixed amount in cents, 2=percentage), `value` (int, required), `name` (String?). Include `fromJson` factory. See spec §4.

- [ ] **Step 4: Create PaymentMethodModel**

Create `lib/features/subscription/model/payment_method_model.dart` with freezed class containing: `id` (int, required), `name` (String, required), `icon` (String?), `payment` (int?). Include `fromJson` factory. See spec §4.

- [ ] **Step 5: Create SubscribeInfoModel**

Create `lib/features/subscription/model/subscribe_info_model.dart` with freezed class containing: `planId` (int?, JsonKey 'plan_id'), `u` (int, Default(0)), `d` (int, Default(0)), `transferEnable` (int, Default(0), JsonKey 'transfer_enable'), `expiredAt` (int?, JsonKey 'expired_at'), `subscribeUrl` (String?, JsonKey 'subscribe_url'), `plan` (PlanModel?). Include `fromJson` factory. See spec §4.

- [ ] **Step 6: Create BillingPeriod enum**

Create `lib/features/subscription/model/billing_period.dart` with enum containing: `monthPrice('month_price', '月付', 1)`, `quarterPrice('quarter_price', '季付', 3)`, `halfYearPrice('half_year_price', '半年付', 6)`, `yearPrice('year_price', '年付', 12)`, `twoYearPrice('two_year_price', '两年付', 24)`, `threeYearPrice('three_year_price', '三年付', 36)`, `onetimePrice('onetime_price', '一次性', 0)`. Include `priceFrom(PlanModel)` and `savingsPercent(PlanModel)` methods. See spec §4.

- [ ] **Step 7: Run build_runner**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: All `.freezed.dart` and `.g.dart` files generated without errors.

- [ ] **Step 8: Commit**

```
git add lib/features/subscription/model/
git commit -m "feat(subscription): add data models (plan, order, coupon, payment, subscribe info, billing period)"
```

---

### Task 2: Repository & Data Providers

**Files:**
- Create: `lib/features/subscription/data/subscription_repository.dart`
- Create: `lib/features/subscription/data/subscription_data_providers.dart`
- Create: `lib/features/subscription/data/subscription_data_providers.g.dart` (generated)

- [ ] **Step 1: Create SubscriptionRepository**

Create `lib/features/subscription/data/subscription_repository.dart`. Class takes `Dio` instance. Implement these methods (all use standard Xboard response format `response.data['data']`):

1. `Future<List<PlanModel>> fetchPlans()` — GET `/api/v1/guest/plan/fetch`
2. `Future<SubscribeInfoModel> getSubscribeInfo()` — GET `/api/v1/user/getSubscribe`
3. `Future<CouponModel> checkCoupon(String code, int planId, String period)` — POST `/api/v1/user/coupon/check`
4. `Future<List<OrderModel>> fetchOrders({int? status})` — GET `/api/v1/user/order/fetch?status=X`
5. `Future<void> cancelOrder(String tradeNo)` — POST `/api/v1/user/order/cancel`
6. `Future<String> createOrder(int planId, String period, {String? couponCode})` — POST `/api/v1/user/order/save`, returns tradeNo from response data
7. `Future<OrderModel> getOrderDetail(String tradeNo)` — GET `/api/v1/user/order/detail?trade_no=X`
8. `Future<List<PaymentMethodModel>> getPaymentMethods()` — GET `/api/v1/user/order/getPaymentMethod`
9. `Future<Map<String, dynamic>> checkout(String tradeNo, int method)` — POST `/api/v1/user/order/checkout`, returns raw response data map
10. `Future<int> checkOrderStatus(String tradeNo)` — GET `/api/v1/user/order/check?trade_no=X`, returns status int

Error handling: catch `DioException`, extract message from `response.data['message']`, throw custom `SubscriptionException`.

Reference `lib/features/auth/data/auth_repository.dart` for Dio patterns (SSL bypass, error extraction).

- [ ] **Step 2: Create data providers**

Create `lib/features/subscription/data/subscription_data_providers.dart`. Define Riverpod providers:

1. `subscriptionRepositoryProvider` — creates `SubscriptionRepository` using the same Dio instance from `authRepositoryProvider` (access via `ref.watch(authRepositoryProvider).dio` — note: need to expose Dio getter on AuthRepository, or create shared Dio provider).

**Important:** The Dio instance must share the auth token. Best approach: extract a shared `xlinkDioProvider` that both AuthRepository and SubscriptionRepository consume. Alternatively, pass the Dio from AuthRepository.

- [ ] **Step 3: Run build_runner**

Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 4: Commit**

```
git add lib/features/subscription/data/
git commit -m "feat(subscription): add repository and data providers"
```

---

### Task 3: Notifiers (State Management)

**Files:**
- Create: `lib/features/subscription/notifier/shop_notifier.dart`
- Create: `lib/features/subscription/notifier/shop_notifier.g.dart` (generated)
- Create: `lib/features/subscription/notifier/checkout_notifier.dart`
- Create: `lib/features/subscription/notifier/checkout_notifier.g.dart` (generated)
- Create: `lib/features/subscription/notifier/order_detail_notifier.dart`
- Create: `lib/features/subscription/notifier/order_detail_notifier.g.dart` (generated)

- [ ] **Step 1: Create ShopNotifier**

`@riverpod` class extending `AsyncNotifier<List<PlanModel>>`. `build()` calls `repo.fetchPlans()`. Add `refresh()` method. Reference: `lib/features/auth/notifier/auth_notifier.dart` for pattern.

- [ ] **Step 2: Create CheckoutNotifier**

`@riverpod` class (family, parameterized by planId int). State class (not freezed, use plain class or record) holding: `selectedPeriod` (BillingPeriod?), `coupon` (CouponModel?), `couponError` (String?), `isSubmitting` (bool), `plan` (PlanModel?).

Methods:
- `build(int planId)` — find plan from ShopNotifier's cached data, auto-select first available period
- `selectPeriod(BillingPeriod)` — update selectedPeriod
- `applyCoupon(String code)` — call `repo.checkCoupon()`, set coupon or couponError
- `clearCoupon()` — reset coupon state
- `submitOrder()` — the key method:
  1. Fetch pending orders (`repo.fetchOrders(status: 0)`)
  2. Cancel each pending order (`repo.cancelOrder()`)
  3. Create new order (`repo.createOrder()`)
  4. Return tradeNo string for navigation

- [ ] **Step 3: Create OrderDetailNotifier**

`@riverpod` class (family, parameterized by tradeNo String). State holding: `order` (OrderModel?), `paymentMethods` (List<PaymentMethodModel>), `selectedMethodId` (int?), `isCheckingOut` (bool), `pollStatus` (String: 'idle'|'polling'|'success'|'failed').

Methods:
- `build(String tradeNo)` — call `repo.getOrderDetail()` and `repo.getPaymentMethods()`, auto-select first method
- `selectPaymentMethod(int id)` — update selection
- `checkout()` — call `repo.checkout()`, parse response: type=0 → `launchUrl(Uri.parse(data['data']))` with `mode: LaunchMode.externalApplication`; type=-1 → mark success directly. Then start polling.
- `_startPolling()` — `Timer.periodic(1 second)`, call `repo.checkOrderStatus()`, when status != 0: cancel timer, call `ref.read(authNotifierProvider.notifier).syncSubscription()`, set pollStatus='success'
- `dispose` — cancel timer

- [ ] **Step 4: Run build_runner**

Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 5: Commit**

```
git add lib/features/subscription/notifier/
git commit -m "feat(subscription): add shop, checkout, order detail notifiers"
```

---

### Task 4: ShopPage UI

**Files:**
- Create: `lib/features/subscription/widget/shop_page.dart`
- Create: `lib/features/subscription/widget/plan_card.dart`

- [ ] **Step 1: Create PlanCard widget**

`StatelessWidget` taking `PlanModel plan` and `VoidCallback onPurchase`. Display:
- Plan name (titleLarge, bold)
- Starting price: find lowest non-null price from plan, format as `¥XX.XX/月` (price in cents, divide by 100)
- Feature list with check icons: traffic (`transferEnable` GB or '不限'), devices (`deviceLimit` or '不限'), speed (`speedLimit` Mbps or '不限速')
- FilledButton "立即购买"

Style: Material 3 Card with `surfaceContainerLow` background, rounded corners (16), elevation 0, border with `outlineVariant.withOpacity(0.15)`.

- [ ] **Step 2: Create ShopPage**

`ConsumerWidget`. AppBar title "订阅套餐". Body watches `shopNotifierProvider`:
- Loading → `Center(child: CircularProgressIndicator())`
- Error → error message + retry button calling `ref.invalidate(shopNotifierProvider)`
- Data → `ListView.builder` of PlanCard widgets

On PlanCard purchase tap: check `ref.read(isAuthenticatedProvider)` — if false, `context.pushNamed('login')`; if true, `context.pushNamed('checkout', pathParameters: {'planId': plan.id.toString()})`.

- [ ] **Step 3: Commit**

```
git add lib/features/subscription/widget/shop_page.dart lib/features/subscription/widget/plan_card.dart
git commit -m "feat(subscription): add ShopPage and PlanCard UI"
```

---

### Task 5: CheckoutPage UI

**Files:**
- Create: `lib/features/subscription/widget/checkout_page.dart`

- [ ] **Step 1: Create CheckoutPage**

`ConsumerStatefulWidget` taking `String planId`. AppBar with back button, title "确认订单".

Body is `ListView` with sections:
1. **Plan info card** — name, traffic/speed/devices stats row, markdown content (use `Text` for now, or `SelectableText`)
2. **Period selection** — `Wrap` of `ChoiceChip` or tappable cards for each available period. Show price (cents→yuan) and savings %. Highlight selected. Only show periods where `period.priceFrom(plan) != null`.
3. **Coupon section** — `TextField` + "验证" `TextButton`. Show success (green text with discount) or error (red text). "清除" button if coupon applied.
4. **Price summary** — subtotal, discount, divider, total in bold primary color.
5. **Submit button** — full-width `FilledButton` "立即下单". Shows `CircularProgressIndicator` when submitting.

On submit: call `checkoutNotifier.submitOrder()`. On success (returns tradeNo), navigate: `context.pushNamed('orderDetail', pathParameters: {'tradeNo': tradeNo})`. On error, show `SnackBar`.

- [ ] **Step 2: Commit**

```
git add lib/features/subscription/widget/checkout_page.dart
git commit -m "feat(subscription): add CheckoutPage UI"
```

---

### Task 6: OrderDetailPage UI

**Files:**
- Create: `lib/features/subscription/widget/order_detail_page.dart`

- [ ] **Step 1: Create OrderDetailPage**

`ConsumerStatefulWidget` taking `String tradeNo`. AppBar title "订单支付".

Body sections:
1. **Order summary card** — plan name, period, trade_no (mono font), total amount
2. **Payment method selection** — `RadioListTile` for each method from `paymentMethods`
3. **Checkout button** — full-width FilledButton "确认支付"
4. **Polling status area** — shown after checkout:
   - 'polling' → `CircularProgressIndicator` + "等待支付确认..."
   - 'success' → check icon + "支付成功！正在同步订阅..." + auto navigate to '/home' after 3 seconds using `Future.delayed`

On checkout tap: call `orderDetailNotifier.checkout()`.

Handle `dispose`: ensure timer is cancelled via notifier.

- [ ] **Step 2: Commit**

```
git add lib/features/subscription/widget/order_detail_page.dart
git commit -m "feat(subscription): add OrderDetailPage UI"
```

---

### Task 7: Route Registration

**Files:**
- Modify: `lib/core/router/go_router/routing_config_notifier.dart`

- [ ] **Step 1: Add imports**

Add imports at top of file:
```dart
import 'package:hiddify/features/subscription/widget/shop_page.dart';
import 'package:hiddify/features/subscription/widget/checkout_page.dart';
import 'package:hiddify/features/subscription/widget/order_detail_page.dart';
```

- [ ] **Step 2: Add routes**

In the settings branch `routes` list (after existing GoRoutes like `general`, before `if (!FeatureFlags.hideAdvancedSettings)` block), add:

```dart
if (FeatureFlags.enableSubscriptionShop) ...[
  GoRoute(
    name: 'shop',
    path: '/shop',
    pageBuilder: (_, state) => customTransition(TransitionType.slide, state.pageKey, const ShopPage()),
  ),
  GoRoute(
    name: 'checkout',
    path: '/checkout/:planId',
    pageBuilder: (_, state) => customTransition(TransitionType.slide, state.pageKey, CheckoutPage(planId: state.pathParameters['planId']!)),
  ),
  GoRoute(
    name: 'orderDetail',
    path: '/order-detail/:tradeNo',
    pageBuilder: (_, state) => customTransition(TransitionType.slide, state.pageKey, OrderDetailPage(tradeNo: state.pathParameters['tradeNo']!)),
  ),
],
```

- [ ] **Step 3: Commit**

```
git add lib/core/router/go_router/routing_config_notifier.dart
git commit -m "feat(subscription): register shop/checkout/orderDetail routes"
```

---

### Task 8: UserModel Extension & Subscribe Info

**Files:**
- Modify: `lib/features/auth/model/user_model.dart`
- Modify: `lib/features/auth/data/auth_repository.dart`
- Modify: `lib/features/auth/notifier/auth_notifier.dart`

- [ ] **Step 1: Extend UserModel**

Add fields to `UserModel` in `lib/features/auth/model/user_model.dart`:
```dart
@JsonKey(name: 'plan_id') int? planId,
@Default(0) int u,
@Default(0) int d,
@JsonKey(name: 'transfer_enable') @Default(0) int transferEnable,
@JsonKey(name: 'expired_at') int? expiredAt,
@JsonKey(name: 'subscribe_url') String? subscribeUrl,
```

- [ ] **Step 2: Add getSubscribeInfo to AuthRepository**

Add method to `AuthRepository` in `lib/features/auth/data/auth_repository.dart`:
```dart
Future<Map<String, dynamic>> getSubscribeInfo() async {
  try {
    final response = await _dio.get('/api/v1/user/getSubscribe');
    return response.data['data'] as Map<String, dynamic>;
  } on DioException catch (e) {
    loggy.error('Get subscribe info failed', e);
    final message = _extractErrorMessage(e);
    throw AuthException(message);
  }
}
```

- [ ] **Step 3: Add refreshSubscribeInfo to AuthNotifier**

Add method to `AuthNotifier` in `lib/features/auth/notifier/auth_notifier.dart`:
```dart
Future<void> refreshSubscribeInfo() async {
  final current = state;
  if (current is! Authenticated) return;
  try {
    final info = await _authRepo.getSubscribeInfo();
    final updatedUser = current.user.copyWith(
      planId: info['plan_id'] as int?,
      u: info['u'] as int? ?? 0,
      d: info['d'] as int? ?? 0,
      transferEnable: info['transfer_enable'] as int? ?? 0,
      expiredAt: info['expired_at'] as int?,
      subscribeUrl: info['subscribe_url'] as String?,
    );
    state = AuthState.authenticated(user: updatedUser, authToken: current.authToken);
  } on AuthException catch (e) {
    loggy.warning('Failed to refresh subscribe info: ${e.message}');
  }
}
```

Call `refreshSubscribeInfo()` at end of `login()` and `register()` methods (after `_syncSubscription`).

- [ ] **Step 4: Run build_runner**

Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 5: Commit**

```
git add lib/features/auth/
git commit -m "feat(auth): extend UserModel with subscription fields, add refreshSubscribeInfo"
```

---

### Task 9: Settings Page Integration

**Files:**
- Modify: `lib/features/settings/overview/settings_page.dart`

- [ ] **Step 1: Add subscription status to user card**

In `SettingsPage.build()`, after the existing user email/status display (around line 96-118), add subscription info display when `isAuthenticated`:

- If `user.planId != null` → show subscription card with: plan info text, traffic progress bar (`(user.u + user.d) / user.transferEnable`), expiry date formatted from `user.expiredAt` unix timestamp
- Change "立即訂閱" button to "续费/升级" when user has active plan, keep "立即订阅" when no plan
- Both buttons navigate to `context.pushNamed('shop')`

- [ ] **Step 2: Add "商店" menu item**

In the first `_MenuGroup` (Utilities group, around line 186-191), add:
```dart
_MenuItem(
  icon: Icons.storefront_rounded,
  title: '订阅商店',
  onTap: () {
    if (ref.read(isAuthenticatedProvider)) {
      context.pushNamed('shop');
    } else {
      context.push('/login');
    }
  },
),
```

- [ ] **Step 3: Commit**

```
git add lib/features/settings/overview/settings_page.dart
git commit -m "feat(subscription): add subscription status display and shop entry to settings"
```

---

### Task 10: Home Page Integration

**Files:**
- Modify: `lib/features/home/widget/home_page.dart`

- [ ] **Step 1: Add subscription prompt card**

In `home_page.dart`, locate the main body content area. Add a conditional card above the connection button when user is authenticated but has no subscription profile:

```dart
// Check conditions
final isAuth = ref.watch(isAuthenticatedProvider);
final hasProfile = ref.watch(hasAnyProfileProvider).valueOrNull ?? false;
final authState = ref.watch(authNotifierProvider);
final user = authState is Authenticated ? authState.user : null;

if (isAuth && !hasProfile) {
  // Show subscription prompt card
  Card(
    color: theme.colorScheme.surfaceContainerHigh,
    child: Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(Icons.notifications_rounded, color: theme.colorScheme.primary),
          Text('您还没有订阅套餐'),
          Text('购买套餐后即可使用高速节点'),
          FilledButton(
            onPressed: () => context.pushNamed('shop'),
            child: Text('立即购买'),
          ),
        ],
      ),
    ),
  );
}
```

Adapt this to fit the existing home page layout structure. Study `home_page.dart` structure before inserting.

- [ ] **Step 2: Commit**

```
git add lib/features/home/widget/home_page.dart
git commit -m "feat(subscription): add no-subscription prompt card on home page"
```

---

### Task 11: Build Verification

- [ ] **Step 1: Run build_runner final pass**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: Clean build, no errors.

- [ ] **Step 2: Verify compilation**

Run: `flutter build apk --debug 2>&1 | Select-Object -Last 20`
Expected: BUILD SUCCESSFUL (or at least no Dart compilation errors).

- [ ] **Step 3: Fix any compilation errors**

Address any import issues, type mismatches, or missing generated files.

- [ ] **Step 4: Final commit**

```
git add -A
git commit -m "feat(subscription): complete subscription plan feature implementation"
```
