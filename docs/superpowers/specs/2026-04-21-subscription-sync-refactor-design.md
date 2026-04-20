# 订阅状态同步重构设计文档

> **目标**：简化订阅状态同步代码，减少后端 API 调用，正常情况不更新节点订阅，同时能自动感知各种状态变化。

## 1. 核心设计原则

- **分离关注点**：将"查询状态"（轻量 1 次 API）与"更新节点"（重量级 profile 导入）彻底分开
- **差异驱动**：只有检测到关键字段变化时才触发节点更新
- **统一入口**：所有状态同步走同一个方法 `checkSubscriptionStatus()`，消除散落各处的调用

## 2. 重构设计

### 2.1 新的方法结构

```
AuthNotifier (重构后)
│
├─ checkSubscriptionStatus({bool force = false})  ← 统一入口
│    ├─ 30 秒去重（force=true 时忽略去重）
│    ├─ getSubscribeInfo()          ← 唯一的 1 次 API 调用
│    ├─ diff(oldState, newState)    ← 比对关键字段
│    ├─ 更新 AuthState              ← 触发所有 UI 响应式更新
│    ├─ 条件触发: _syncNodes()      ← 仅 plan_id/subscribe_url 变化时
│    ├─ 条件触发: _forceDisconnect() ← can_connect_vpn=false 或 plan 删除时
│    └─ 条件触发: _clearProfiles()   ← plan 被删除时
│
├─ refreshFullProfile()             ← 手动刷新按钮专用
│    ├─ getUserInfo()               ← 拉取完整用户信息（含余额等）
│    └─ checkSubscriptionStatus(force: true)
│
├─ forceNodeSync()                  ← 首页同步按钮专用
│    ├─ checkSubscriptionStatus(force: true)
│    └─ _syncNodes()                ← 强制更新节点（无论是否变化）
│
├─ _syncNodes()                     ← 内部方法，拉取订阅 URL + 导入 profile
├─ _forceDisconnect()               ← 内部方法，强制断开 VPN
├─ _clearProfiles()                 ← 内部方法，清空本地节点
└─ _handleAuthException()           ← 处理 401/403，强制登出 + 断连
```

### 2.2 差异比对决策矩阵

| 变化 | 更新 UI | 同步节点 | 断开 VPN | 清空节点 |
|------|---------|---------|---------|---------|
| 无变化 | ✅ | ❌ | ❌ | ❌ |
| 仅流量 (u/d) 变化 | ✅ | ❌ | ❌ | ❌ |
| plan_id 变化（升级/更换） | ✅ | ✅ | ❌ | ❌ |
| subscribe_url 变化 | ✅ | ✅ | ❌ | ❌ |
| plan_id: null → 有值 | ✅ | ✅ | ❌ | ❌ |
| plan_id: 有值 → null | ✅ | ❌ | ✅ | ✅ |
| can_connect_vpn: true → false | ✅ | ❌ | ✅ | ❌ |
| can_connect_vpn: false → true（有套餐） | ✅ | ✅ | ❌ | ❌ |
| HTTP 401/403 | ❌ | ❌ | ✅ | ✅ + 登出 |

### 2.3 触发点规划

| 触发点 | 调用方法 | API 次数 | 说明 |
|--------|---------|---------|------|
| App 冷启动 (build) | `checkSubscriptionStatus()` | 1 | 恢复 token 后检查 |
| App resumed | `checkSubscriptionStatus()` | 0-1 | 30 秒去重 |
| 首页加载 | 无 | 0 | 依赖 build/resumed 已获取的状态 |
| 个人中心加载 | 无 | 0 | 使用缓存状态，提供手动刷新按钮 |
| 个人中心手动刷新按钮 | `refreshFullProfile()` | 2 | force + 含完整用户信息 |
| 从支付页面返回/支付成功 | `checkSubscriptionStatus(force: true)` | 1 | 跳过去重 |
| 设备管理移除设备后 | `checkSubscriptionStatus(force: true)` | 1 | 跳过去重 |
| 首页同步按钮 | `forceNodeSync()` | 1 | 强制同步节点 |
| 登录/注册成功 | `_syncNodes()` (直接) | 1 | 首次导入节点 |

### 2.4 文件变更清单

| 文件 | 变更 |
|------|------|
| `auth_notifier.dart` | 重构核心：新增 checkSubscriptionStatus / refreshFullProfile / forceNodeSync / _forceDisconnect / 差异比对 / 30秒去重 |
| `home_page.dart` | 移除冗余 useEffect/resumed/then 调用，简化同步按钮 |
| `settings_page.dart` | 移除 useEffect，增加刷新按钮 |
| `device_manage_page.dart` | 简化为 checkSubscriptionStatus(force: true) |
| `order_detail_notifier.dart` | 支付成功改为 checkSubscriptionStatus(force: true) |
