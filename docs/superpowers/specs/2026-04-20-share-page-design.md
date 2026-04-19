# Hiddify App 分享页面（邀请返现）设计规格

## 概述

在 Hiddify Flutter App 中实现轻量级邀请分享页面，连接 Xboard 后端 API。核心功能：展示佣金统计、管理邀请码、复制/系统分享邀请链接。不含佣金流水表、划转和提现功能（留在网页端）。

---

## 架构

### 新建文件

```
lib/features/share/
├── data/
│   └── share_repository.dart      # API 调用（invite/fetch, invite/save, comm/config）
├── model/
│   └── invite_data.dart           # Freezed 数据模型
│   └── invite_data.freezed.dart   # 生成文件
│   └── invite_data.g.dart         # 生成文件
├── notifier/
│   └── share_notifier.dart        # Riverpod AsyncNotifier
│   └── share_notifier.g.dart      # 生成文件
└── widget/
    └── share_page.dart            # 页面 UI
```

### 修改文件

| 文件 | 修改内容 |
|------|----------|
| `lib/core/router/go_router/routing_config_notifier.dart` | 添加 `/share` 路由（settings 分支下） |
| `lib/features/settings/overview/settings_page.dart` | "分享"菜单 `onTap` 改为 `context.pushNamed('share')` |
| `assets/translations/en.i18n.json` | 添加 `pages.share` 命名空间 |
| `assets/translations/zh-CN.i18n.json` | 添加 `pages.share` 命名空间 |
| `assets/translations/zh-TW.i18n.json` | 添加 `pages.share` 命名空间 |

修改翻译文件后需运行 `dart run slang` 重新生成。

### 依赖

- 复用 `AuthRepository` 中已有的 `Dio` 实例（带 auth token）
- `share_plus` 包调用系统原生分享（需确认 pubspec.yaml 中是否已有，没有则添加）
- `freezed` / `json_serializable`（已有）
- 不引入新的状态管理、路由或 UI 框架

---

## API 端点

| 方法 | 端点 | 用途 |
|------|------|------|
| GET | `/api/v1/user/invite/fetch` | 邀请码列表 + 统计（余额、人数、佣金） |
| GET | `/api/v1/user/invite/save` | 生成新邀请码 |
| GET | `/api/v1/user/comm/config` | 佣金配置（三级分销比例、货币符号、提现方式） |

### invite/fetch 响应结构

```json
{
  "data": {
    "codes": [{ "code": "Zz6xW5r7", "created_at": 1234567890 }],
    "stat": [invite_count, total_commission_amount, unknown, base_rate],
    "commission_rate": 10,
    "commission_balance": 0,
    "commission_pending_amount": 0
  }
}
```

### comm/config 关键字段

```json
{
  "data": {
    "commission_distribution_enable": 1,
    "commission_distribution_l1": 60,
    "commission_distribution_l2": 30,
    "commission_distribution_l3": 10,
    "currency_symbol": "¥",
    "withdraw_methods": ["支付宝", "USDT", "Paypal"],
    "withdraw_close": 0
  }
}
```

---

## 数据模型

```dart
@freezed
class InviteData with _$InviteData {
  const factory InviteData({
    required List<String> codes,
    required int inviteCount,
    required int baseRate,
    required bool isDistributionEnabled,
    required double commissionRateL1,
    required double commissionRateL2,
    required double commissionRateL3,
    required int commissionBalance,      // 分（cents）
    required int pendingAmount,          // 分
    required int totalCommission,        // 分
    required String currencySymbol,
    required String siteUrl,             // 基础 URL，用于拼接邀请链接
  }) = _InviteData;
}
```

### 佣金比例计算逻辑

与 Xboard 网页端 `Invite.jsx` 一致：

```
baseRate = stat[3]

if commission_distribution_enable == 1:
  L1 = baseRate × commission_distribution_l1 / 100
  L2 = baseRate × commission_distribution_l2 / 100
  L3 = baseRate × commission_distribution_l3 / 100
else:
  L1 = baseRate
  L2 = 0
  L3 = 0
```

### 邀请链接格式

```
{siteUrl}/#/register?code={code}
```

`siteUrl` 取自 `AuthRepository.baseUrl`（当前为 `https://47.79.38.161`）。

---

## Notifier 状态管理

```dart
@riverpod
class ShareNotifier extends _$ShareNotifier {
  @override
  Future<InviteData> build() async {
    // 并发请求 invite/fetch + comm/config
    // 合并为 InviteData
  }

  Future<void> generateCode() async {
    // POST invite/save → 重新 fetch → 刷新状态
  }
}
```

### 状态流

```
页面 mount → shareNotifier.build()
  → 并发请求 invite/fetch + comm/config
  → 合并为 InviteData
  → AsyncValue<InviteData> 驱动 UI

生成邀请码 → shareNotifier.generateCode()
  → GET invite/save
  → 重新 build() → 刷新状态

复制链接 → 本地 Clipboard.setData() + SnackBar

系统分享 → Share.share(url) via share_plus
```

---

## 页面 UI 设计

页面风格与 `settings_page.dart` 保持一致（深色主题、圆角卡片、Material 3）。

### AppBar

- 左侧：返回按钮
- 标题：`t.pages.share.title`（居中）

### 区域 1：佣金概览卡片

一个 `Container` 卡片，样式同设置页用户资料卡片。

- 左侧区域：
  - 小标签："可用余额" / "Commission Balance"
  - 大字金额：`¥ {commissionBalance / 100}`
- 右侧区域（或下方，根据空间）：统计标签网格
  - **分销关闭时：** 2×2 网格
    - 邀请人数 | 返利比例（`{baseRate}%`）
    - 待确认佣金 | 累计佣金
  - **分销开启时：** 自适应网格（2×3 或 3×2）
    - 邀请人数 | L1 `{rate}%` | L2 `{rate}%`
    - L3 `{rate}%` | 待确认佣金 | 累计佣金

每个统计项为小卡片，`surfaceContainerHighest` 底色，标签在上、数值在下。

### 区域 2：邀请码列表

- 标题行：「邀请链接」+ 右侧「生成邀请码」按钮
  - 按钮带 loading 状态（`CircularProgressIndicator` 替换图标）
  - 调用 `shareNotifier.generateCode()`

- **空状态：**
  - `link_off` 图标 + 提示文字

- **有码时：** 每个码一张卡片（`surfaceContainer` 底色，圆角 16）
  - 顶部：邀请码 badge（mono 字体，`primary` 色，`surfaceContainerHighest` 底色）
  - 中间：只读 `TextField` 展示完整链接
  - 底部两个按钮并排：
    - 📋 **复制链接** — `Clipboard.setData()` + SnackBar "已复制！"
    - 📤 **分享** — `Share.share(message)` 调用系统分享
      - 分享文本：`t.pages.share.shareMessage`（含链接）

### 状态处理

| 状态 | 展示 |
|------|------|
| 加载中 | 骨架屏 shimmer（3 个圆角矩形 placeholder） |
| 未登录 | 提示卡片 + "前往登录" 按钮 → push `/login` |
| API 错误 | 错误图标 + 错误信息 + "重试" 按钮 |
| 正常 | 佣金概览 + 邀请码列表 |

---

## 多语言 (i18n)

### en.i18n.json 新增

```json
"share": {
  "title": "Invite & Earn",
  "commissionBalance": "Commission Balance",
  "inviteCount": "Invitees",
  "commissionRate": "Commission Rate",
  "commissionRateL1": "L1 Rate",
  "commissionRateL2": "L2 Rate",
  "commissionRateL3": "L3 Rate",
  "pendingCommission": "Pending",
  "totalCommission": "Total Earned",
  "inviteLinks": "Invite Links",
  "generateCode": "Generate Code",
  "generating": "Generating...",
  "noCodesYet": "No invite codes yet. Tap generate to create one.",
  "copyLink": "Copy Link",
  "copied": "Copied!",
  "shareLink": "Share",
  "shareMessage": "Join me on XLINK VPN! Sign up here: ${url}",
  "loginRequired": "Please log in to use the invite feature.",
  "loginButton": "Log In",
  "errorRetry": "Retry"
}
```

### zh-CN.i18n.json 新增

```json
"share": {
  "title": "邀请返现",
  "commissionBalance": "可用余额",
  "inviteCount": "邀请人数",
  "commissionRate": "返利比例",
  "commissionRateL1": "L1 比例",
  "commissionRateL2": "L2 比例",
  "commissionRateL3": "L3 比例",
  "pendingCommission": "待确认佣金",
  "totalCommission": "累计佣金",
  "inviteLinks": "邀请链接",
  "generateCode": "生成邀请码",
  "generating": "生成中...",
  "noCodesYet": "暂无邀请码，点击生成按钮创建。",
  "copyLink": "复制链接",
  "copied": "已复制！",
  "shareLink": "分享",
  "shareMessage": "加入 XLINK VPN，注册链接：${url}",
  "loginRequired": "请先登录以使用邀请功能。",
  "loginButton": "前往登录",
  "errorRetry": "重试"
}
```

### zh-TW.i18n.json 新增

```json
"share": {
  "title": "邀請返現",
  "commissionBalance": "可用餘額",
  "inviteCount": "邀請人數",
  "commissionRate": "返利比例",
  "commissionRateL1": "L1 比例",
  "commissionRateL2": "L2 比例",
  "commissionRateL3": "L3 比例",
  "pendingCommission": "待確認佣金",
  "totalCommission": "累計佣金",
  "inviteLinks": "邀請連結",
  "generateCode": "生成邀請碼",
  "generating": "生成中...",
  "noCodesYet": "暫無邀請碼，點擊生成按鈕建立。",
  "copyLink": "複製連結",
  "copied": "已複製！",
  "shareLink": "分享",
  "shareMessage": "加入 XLINK VPN，註冊連結：${url}",
  "loginRequired": "請先登入以使用邀請功能。",
  "loginButton": "前往登入",
  "errorRetry": "重試"
}
```

翻译键位于 `pages.share` 命名空间下，代码中通过 `t.pages.share.title` 访问。

---

## 路由集成

在 `routing_config_notifier.dart` 的 settings 分支中添加：

```dart
GoRoute(
  name: 'share',
  path: '/share',
  pageBuilder: (_, state) => customTransition(
    TransitionType.slide, state.pageKey, const SharePage(),
  ),
),
```

与 `trafficRecords`、`ticketCenter` 等路由同级。需要 `FeatureFlags.enableXlinkAuth` 开启时才生效（因为邀请功能依赖用户登录）。

---

## 设置页入口

`settings_page.dart` 第285行：

```dart
// 修改前
_MenuItem(icon: Icons.share_rounded, title: '分享', onTap: () {}),

// 修改后
_MenuItem(
  icon: Icons.share_rounded,
  title: t.pages.share.title,
  onTap: () {
    if (ref.read(isAuthenticatedProvider)) {
      context.pushNamed('share');
    } else {
      context.push('/login');
    }
  },
),
```

---

## 不在此次范围

- 佣金流水明细表（在网页端查看）
- 划转弹窗（佣金转余额）
- 提现弹窗（申请提现）
- 其他语言翻译文件（ar, es, fa, fr, id, pt-BR, ru, tr）— 后续按需补充
