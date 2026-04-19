# Hiddify App 订阅计划功能设计

> 参考 xboard-user-custom 的订阅购买流程，在 Hiddify Flutter App 中实现原生订阅计划功能。

## 1. 功能概述

### 核心流程

三个独立页面，对应 xboard 后端 API：

1. **ShopPage（套餐展示）** — 浏览所有可购买套餐
2. **CheckoutPage（结算下单）** — 选周期、填优惠券、创建订单
3. **OrderDetailPage（订单支付）** — 选支付方式、浏览器支付、自动轮询状态

### 关键行为

- **自动取消未付订单**：下新单前自动查询并取消所有 status=0 的旧订单
- **系统浏览器支付**：checkout 返回的支付链接用 `url_launcher` 打开系统浏览器
- **自动轮询**：支付页每 1 秒轮询订单状态，成功后自动同步订阅并返回首页
- **订阅状态展示**：首页和个人中心从 API 获取真实订阅数据（套餐名、流量、到期日）

### 入口

| 入口 | 位置 | 触发条件 |
|---|---|---|
| 首页引导卡片 | `home_page.dart` | 已登录 + 无活跃订阅 profile |
| 个人中心「立即订阅」 | `settings_page.dart` 用户卡片 | 已登录 + 无订阅 |
| 个人中心「商店」菜单 | `settings_page.dart` 菜单组 | 始终可见（需登录） |

### UI 风格

融入 Hiddify 现有 Material 3 主题体系，与其他页面保持一致。

---

## 2. 架构设计

### 目录结构

```
lib/features/subscription/
├── data/
│   ├── subscription_repository.dart      # Xboard 订阅相关 API 调用
│   └── subscription_data_providers.dart   # Riverpod provider 定义
├── model/
│   ├── plan_model.dart                    # 套餐 (freezed)
│   ├── order_model.dart                   # 订单 (freezed)
│   ├── coupon_model.dart                  # 优惠券验证结果 (freezed)
│   ├── payment_method_model.dart          # 支付方式 (freezed)
│   ├── subscribe_info_model.dart          # 用户订阅信息 (freezed)
│   └── billing_period.dart                # 周期枚举
├── notifier/
│   ├── shop_notifier.dart                 # 套餐列表状态管理
│   ├── checkout_notifier.dart             # 结算流程状态管理
│   └── order_detail_notifier.dart         # 订单详情+支付+轮询
└── widget/
    ├── shop_page.dart                     # 套餐展示页
    ├── plan_card.dart                     # 套餐卡片组件
    ├── checkout_page.dart                 # 结算页
    └── order_detail_page.dart             # 订单详情+支付页
```

### 分层职责

| 层 | 职责 | 模式 |
|---|---|---|
| **data** | HTTP 请求封装，JSON 解析 | 复用 AuthRepository 的 Dio 实例（共享 baseUrl + auth token） |
| **model** | 数据结构定义 | freezed + json_serializable，字段映射 xboard API |
| **notifier** | 业务逻辑 + UI 状态 | Riverpod AsyncNotifier，处理加载/错误/成功状态 |
| **widget** | 页面 + 组件 | Material 3 组件，消费 notifier 状态 |

---

## 3. API 清单

| 功能 | 方法 | 端点 | 鉴权 |
|---|---|---|---|
| 获取套餐列表 | GET | `/api/v1/guest/plan/fetch` | 无需 |
| 获取用户订阅信息 | GET | `/api/v1/user/getSubscribe` | 需要 |
| 验证优惠券 | POST | `/api/v1/user/coupon/check` | 需要 |
| 查询待付订单 | GET | `/api/v1/user/order/fetch?status=0` | 需要 |
| 取消订单 | POST | `/api/v1/user/order/cancel` | 需要 |
| 创建订单 | POST | `/api/v1/user/order/save` | 需要 |
| 订单详情 | GET | `/api/v1/user/order/detail?trade_no=xxx` | 需要 |
| 支付方式列表 | GET | `/api/v1/user/order/getPaymentMethod` | 需要 |
| 发起支付 | POST | `/api/v1/user/order/checkout` | 需要 |
| 轮询订单状态 | GET | `/api/v1/user/order/check?trade_no=xxx` | 需要 |

---

## 4. 数据模型

### PlanModel — 套餐

```dart
@freezed
class PlanModel with _$PlanModel {
  const factory PlanModel({
    required int id,
    required String name,
    String? content,                                         // Markdown 描述
    @JsonKey(name: 'transfer_enable') int? transferEnable,   // 流量 GB
    @JsonKey(name: 'speed_limit') int? speedLimit,           // 速率 Mbps
    @JsonKey(name: 'device_limit') int? deviceLimit,         // 设备数
    @JsonKey(name: 'month_price') int? monthPrice,           // 月付 (分)
    @JsonKey(name: 'quarter_price') int? quarterPrice,       // 季付
    @JsonKey(name: 'half_year_price') int? halfYearPrice,    // 半年
    @JsonKey(name: 'year_price') int? yearPrice,             // 年付
    @JsonKey(name: 'two_year_price') int? twoYearPrice,      // 两年
    @JsonKey(name: 'three_year_price') int? threeYearPrice,  // 三年
    @JsonKey(name: 'onetime_price') int? onetimePrice,       // 一次性
  }) = _PlanModel;

  factory PlanModel.fromJson(Map<String, Object?> json) => _$PlanModelFromJson(json);
}
```

### OrderModel — 订单

```dart
@freezed
class OrderModel with _$OrderModel {
  const factory OrderModel({
    @JsonKey(name: 'trade_no') required String tradeNo,
    required int status,                                      // 0待付 1处理中 2已取消 3已完成 4已折抵
    @JsonKey(name: 'total_amount') required int totalAmount,  // 分
    @JsonKey(name: 'discount_amount') @Default(0) int discountAmount,
    @JsonKey(name: 'handling_amount') @Default(0) int handlingAmount,
    String? period,
    PlanModel? plan,
    @JsonKey(name: 'created_at') int? createdAt,
  }) = _OrderModel;

  factory OrderModel.fromJson(Map<String, Object?> json) => _$OrderModelFromJson(json);
}
```

### CouponModel — 优惠券验证结果

```dart
@freezed
class CouponModel with _$CouponModel {
  const factory CouponModel({
    required int type,    // 1=固定金额(分) 2=百分比
    required int value,   // type=1 → 分, type=2 → 百分比
    String? name,
  }) = _CouponModel;

  factory CouponModel.fromJson(Map<String, Object?> json) => _$CouponModelFromJson(json);
}
```

### PaymentMethodModel — 支付方式

```dart
@freezed
class PaymentMethodModel with _$PaymentMethodModel {
  const factory PaymentMethodModel({
    required int id,
    required String name,
    String? icon,
    int? payment,
  }) = _PaymentMethodModel;

  factory PaymentMethodModel.fromJson(Map<String, Object?> json) => _$PaymentMethodModelFromJson(json);
}
```

### SubscribeInfoModel — 用户当前订阅信息

```dart
@freezed
class SubscribeInfoModel with _$SubscribeInfoModel {
  const factory SubscribeInfoModel({
    @JsonKey(name: 'plan_id') int? planId,
    @Default(0) int u,                                       // 上传 bytes
    @Default(0) int d,                                       // 下载 bytes
    @JsonKey(name: 'transfer_enable') @Default(0) int transferEnable,  // 总流量 bytes
    @JsonKey(name: 'expired_at') int? expiredAt,             // 到期 unix timestamp
    @JsonKey(name: 'subscribe_url') String? subscribeUrl,
    PlanModel? plan,
  }) = _SubscribeInfoModel;

  factory SubscribeInfoModel.fromJson(Map<String, Object?> json) => _$SubscribeInfoModelFromJson(json);
}
```

### BillingPeriod — 周期枚举

```dart
enum BillingPeriod {
  monthPrice('month_price', '月付', 1),
  quarterPrice('quarter_price', '季付', 3),
  halfYearPrice('half_year_price', '半年付', 6),
  yearPrice('year_price', '年付', 12),
  twoYearPrice('two_year_price', '两年付', 24),
  threeYearPrice('three_year_price', '三年付', 36),
  onetimePrice('onetime_price', '一次性', 0);

  const BillingPeriod(this.apiKey, this.label, this.months);
  final String apiKey;
  final String label;
  final int months;

  /// 从套餐中提取该周期的价格
  int? priceFrom(PlanModel plan) => switch (this) {
    monthPrice => plan.monthPrice,
    quarterPrice => plan.quarterPrice,
    halfYearPrice => plan.halfYearPrice,
    yearPrice => plan.yearPrice,
    twoYearPrice => plan.twoYearPrice,
    threeYearPrice => plan.threeYearPrice,
    onetimePrice => plan.onetimePrice,
  };

  /// 计算相对月付的折扣百分比
  int savingsPercent(PlanModel plan) {
    if (months <= 1 || plan.monthPrice == null || plan.monthPrice == 0) return 0;
    final price = priceFrom(plan);
    if (price == null) return 0;
    final monthlyEquiv = price / months;
    return ((1 - monthlyEquiv / plan.monthPrice!) * 100).round();
  }
}
```

---

## 5. 页面详细设计

### 5.1 ShopPage — 套餐展示

**状态管理**：`ShopNotifier` — `AsyncNotifier<List<PlanModel>>`

**页面结构**：

```
┌──────────────────────────┐
│  AppBar: "订阅套餐"       │
├──────────────────────────┤
│  [加载中] → CircularProgressIndicator
│  [加载失败] → 错误提示 + 重试按钮
│  [成功] ↓
├──────────────────────────┤
│  PlanCard (套餐 1)        │
│  ┌────────────────────┐  │
│  │ 套餐名称             │  │
│  │ ¥XX/月 起            │  │
│  │ ✓ XXX GB 流量        │  │
│  │ ✓ 最高 X 台设备      │  │
│  │ ✓ 不限速 / XXX Mbps  │  │
│  │ [立即购买] 按钮       │  │
│  └────────────────────┘  │
│                          │
│  PlanCard (套餐 2) ...    │
└──────────────────────────┘
```

**逻辑**：
- `build()` 中调用 `GET /api/v1/guest/plan/fetch`，无需登录
- 显示最低可用价格作为"起步价"（优先 monthPrice）
- 点击「立即购买」→ 检查登录状态 → 未登录则跳转 `/login` → 已登录则 `pushNamed('checkout', pathParameters: {'planId': plan.id})`

### 5.2 CheckoutPage — 结算下单

**接收参数**：`planId`（从路由 pathParameters 获取）

**状态管理**：`CheckoutNotifier` — 管理选中周期、优惠券验证、下单流程

**页面结构**：

```
┌──────────────────────────┐
│  AppBar: ← 返回 | "确认订单" │
├──────────────────────────┤
│  套餐信息卡片              │
│  ┌────────────────────┐  │
│  │ 套餐名称 + 高速标签   │  │
│  │ 流量 | 速率 | 设备数  │  │
│  │ (Markdown 描述展开)   │  │
│  └────────────────────┘  │
├──────────────────────────┤
│  付费周期选择              │
│  ┌────────┐ ┌────────┐  │
│  │ 月付    │ │ 季付    │  │
│  │ ¥29.90  │ │ ¥79.90  │  │
│  │ ● 选中  │ │ 省10%   │  │
│  └────────┘ └────────┘  │
│  (仅显示 price != null 的周期)
├──────────────────────────┤
│  优惠券                   │
│  [________输入框____] [验证] │
│  ✓ 已抵扣: -¥10.00       │
│  (或错误提示)              │
├──────────────────────────┤
│  价格汇总                  │
│  套餐费用: ¥29.90          │
│  优惠: -¥10.00            │
│  ─────────────────        │
│  合计: ¥19.90             │
│                          │
│  [立即下单] (全宽按钮)     │
└──────────────────────────┘
```

**下单流程**：

```
用户点击「立即下单」
  → 显示 loading
  → GET /user/order/fetch?status=0 查询待付订单
  → 逐一 POST /user/order/cancel 取消旧订单
  → POST /user/order/save 创建新订单
     body: { plan_id, period: selectedPeriod.apiKey, coupon_code? }
  → 获取 tradeNo
  → pushNamed('orderDetail', pathParameters: {'tradeNo': tradeNo})
```

### 5.3 OrderDetailPage — 订单支付

**接收参数**：`tradeNo`（从路由 pathParameters 获取）

**状态管理**：`OrderDetailNotifier` — 管理订单详情、支付方式列表、轮询

**页面结构**：

```
┌──────────────────────────┐
│  AppBar: ← | "订单支付"    │
├──────────────────────────┤
│  订单摘要卡片              │
│  ┌────────────────────┐  │
│  │ 套餐名称: Pro Plan   │  │
│  │ 周期: 月付           │  │
│  │ 订单号: 202604...    │  │
│  │ 合计: ¥19.90         │  │
│  └────────────────────┘  │
├──────────────────────────┤
│  选择支付方式              │
│  ┌────────────────────┐  │
│  │ ○ 支付宝             │  │
│  │ ● 微信支付           │  │
│  │ ○ USDT              │  │
│  └────────────────────┘  │
├──────────────────────────┤
│  [确认支付] (全宽按钮)     │
├──────────────────────────┤
│  ─── 等待支付状态 ───      │
│  🔄 等待支付确认...        │
│  (自动轮询中，每1秒)       │
│                          │
│  ─── 支付成功状态 ───      │
│  ✅ 支付成功！             │
│  正在同步订阅...           │
│  (3秒后自动返回首页)       │
└──────────────────────────┘
```

**支付流程**：

```
用户选择支付方式 → 点击「确认支付」
  → POST /user/order/checkout { trade_no, method }
  → 解析响应:
     type=0  → url_launcher.launchUrl(data.data) 系统浏览器打开
     type=-1 → 余额抵扣完成，直接标记成功
  → 启动 Timer.periodic(Duration(seconds: 1)) 轮询
     GET /user/order/check?trade_no=xxx
  → status != 0 时:
     → 停止 Timer
     → 调用 authNotifier.syncSubscription() 同步订阅配置
     → 调用 authNotifier.refreshSubscribeInfo() 刷新订阅数据
     → 显示成功提示
     → 延迟 3 秒 → context.go('/home') 返回首页
```

---

## 6. 订阅状态展示

### 6.1 UserModel 扩展

在现有 `UserModel` 中新增订阅相关字段：

```dart
// 新增字段
@JsonKey(name: 'plan_id') int? planId,
@Default(0) int u,
@Default(0) int d,
@JsonKey(name: 'transfer_enable') @Default(0) int transferEnable,
@JsonKey(name: 'expired_at') int? expiredAt,
@JsonKey(name: 'subscribe_url') String? subscribeUrl,
```

### 6.2 个人中心展示

用户信息卡片根据订阅状态分三种显示：

**状态 A：未登录**
```
┌─────────────────────────────┐
│  👤 Guest User              │
│  ● 访客                     │
│  [登入 / 註冊] 按钮          │
└─────────────────────────────┘
```

**状态 B：已登录 + 无订阅**（plan_id 为空或无 profile）
```
┌─────────────────────────────┐
│  👤 user@email.com          │
│  ● 已登录                    │
│  [立即订阅] 渐变按钮          │
└─────────────────────────────┘
```

**状态 C：已登录 + 有订阅**
```
┌─────────────────────────────────┐
│  👤 user@email.com              │
│  ● Premium Member               │
│                                 │
│  ┌──── 当前套餐 ────────────┐   │
│  │ Pro Plan · 月付           │   │
│  │ 流量: 45.2GB / 200GB     │   │
│  │ [████████░░░░] 22.6%     │   │
│  │ 到期: 2026-05-20          │   │
│  └──────────────────────────┘   │
│                                 │
│  [续费/升级]                     │
└─────────────────────────────────┘
```

### 6.3 首页展示

在连接按钮上方区域：

**已登录 + 无订阅** → 显示引导卡片：
```
┌──────────────────────────────┐
│  🔔 您还没有订阅套餐           │
│  购买套餐后即可使用高速节点     │
│  [立即购买]                   │
└──────────────────────────────┘
```

**已登录 + 有订阅** → 现有数据卡片使用 API 真实数据展示流量/到期。

### 6.4 数据刷新时机

| 时机 | 动作 |
|---|---|
| 登录/注册成功 | 自动调用 `getSubscribeInfo()` |
| 支付成功后 | 同步订阅 + 刷新订阅信息 |
| 进入个人中心 | 刷新订阅信息 |
| App 恢复前台 | 如有 token，刷新订阅信息 |

---

## 7. 路由注册

在 `routing_config_notifier.dart` 的 settings branch 子路由中添加：

```dart
if (FeatureFlags.enableSubscriptionShop) ...[
  GoRoute(
    name: 'shop',
    path: '/shop',
    pageBuilder: (_, state) => customTransition(
      TransitionType.slide, state.pageKey, const ShopPage(),
    ),
  ),
  GoRoute(
    name: 'checkout',
    path: '/checkout/:planId',
    pageBuilder: (_, state) => customTransition(
      TransitionType.slide, state.pageKey,
      CheckoutPage(planId: state.pathParameters['planId']!),
    ),
  ),
  GoRoute(
    name: 'orderDetail',
    path: '/order-detail/:tradeNo',
    pageBuilder: (_, state) => customTransition(
      TransitionType.slide, state.pageKey,
      OrderDetailPage(tradeNo: state.pathParameters['tradeNo']!),
    ),
  ),
],
```

---

## 8. 修改文件清单

### 新建文件

| 文件 | 说明 |
|---|---|
| `lib/features/subscription/data/subscription_repository.dart` | API 调用封装 |
| `lib/features/subscription/data/subscription_data_providers.dart` | Riverpod providers |
| `lib/features/subscription/model/plan_model.dart` | 套餐模型 |
| `lib/features/subscription/model/order_model.dart` | 订单模型 |
| `lib/features/subscription/model/coupon_model.dart` | 优惠券模型 |
| `lib/features/subscription/model/payment_method_model.dart` | 支付方式模型 |
| `lib/features/subscription/model/subscribe_info_model.dart` | 订阅信息模型 |
| `lib/features/subscription/model/billing_period.dart` | 周期枚举 |
| `lib/features/subscription/notifier/shop_notifier.dart` | 套餐列表状态 |
| `lib/features/subscription/notifier/checkout_notifier.dart` | 结算状态 |
| `lib/features/subscription/notifier/order_detail_notifier.dart` | 订单+支付状态 |
| `lib/features/subscription/widget/shop_page.dart` | 套餐展示页 |
| `lib/features/subscription/widget/plan_card.dart` | 套餐卡片组件 |
| `lib/features/subscription/widget/checkout_page.dart` | 结算页 |
| `lib/features/subscription/widget/order_detail_page.dart` | 订单支付页 |

### 修改文件

| 文件 | 修改内容 |
|---|---|
| `lib/features/auth/model/user_model.dart` | 新增订阅字段 (planId/u/d/transferEnable/expiredAt/subscribeUrl) |
| `lib/features/auth/data/auth_repository.dart` | 新增 `getSubscribeInfo()` 方法 |
| `lib/features/auth/notifier/auth_notifier.dart` | 新增 `refreshSubscribeInfo()`，login/register 后自动调用 |
| `lib/core/router/go_router/routing_config_notifier.dart` | 添加 shop/checkout/orderDetail 三条路由 |
| `lib/features/settings/overview/settings_page.dart` | 用户卡片增加订阅状态展示 + 「商店」菜单项 + 「续费/升级」按钮 |
| `lib/features/home/widget/home_page.dart` | 增加无订阅引导卡片 |

### 依赖

- `url_launcher` — 打开系统浏览器（pubspec.yaml 中已有）
- `freezed` / `json_serializable` / `build_runner` — 代码生成（已有）
