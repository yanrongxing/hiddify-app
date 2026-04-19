/// Xlink 定制功能开关配置
///
/// 控制定制版 App 中各功能的显示/隐藏。
/// 修改后需要完整重启（非热重载）才能生效。
/// 设为 false 即恢复 Hiddify 原版行为。
class FeatureFlags {
  const FeatureFlags._();

  /// 【登录注册模块】
  /// = true  → 启用 Xlink 登录/注册功能：
  ///           • 路由中注册 /login 页面
  ///           • 设置页底部显示「登录/注册」或「退出登录」按钮
  ///           • 跳过原版引导页（语言选择 + 服务条款）
  ///           • 游客可自由使用 App，仅进入个人中心时要求登录
  /// = false → 使用原版 Hiddify 流程（无登录，显示引导页）
  static const bool enableXlinkAuth = true;

  /// 【隐藏高级设置】
  /// = true  → 隐藏以下设置项（路由+设置页同步隐藏）：
  ///           • 设置 → 路由规则 (Route Options)
  ///           • 设置 → DNS 选项
  ///           • 设置 → 入站选项 (Inbound Options)
  ///           • 设置 → TLS 分片 (TLS Tricks)
  ///           • 设置 → WARP 选项
  ///           • 首页右上角「快速设置」齿轮按钮
  /// = false → 显示所有原版设置项
  static const bool hideAdvancedSettings = false;

  /// 【订阅商店】（尚未实现 UI）
  /// = true  → 启用订阅套餐购买页面（待开发）
  /// = false → 不显示购买入口
  static const bool enableSubscriptionShop = true;

  /// 【隐藏手动添加节点】
  /// = true  → 隐藏以下 UI：
  ///           • 首页右上角「+」添加配置按钮
  ///           节点由 Xboard 订阅自动同步，用户无需手动添加
  /// = false → 保留原版手动添加按钮
  static const bool hideManualProfileAdd = true;

  /// 【隐藏分应用代理】
  /// = true  → 隐藏：设置 → 路由规则 → 分应用代理 (Per-App Proxy)
  ///           该功能对普通用户过于复杂，建议隐藏
  /// = false → 保留分应用代理入口
  static const bool hidePerAppProxy = true;

  /// 【隐藏路由规则】（预留，暂未接入）
  /// = true  → 隐藏：设置 → 路由规则 整个入口
  /// = false → 保留路由规则入口
  static const bool hideRouteRules = false;

  /// 【品牌替换】（预留，暂未实现）
  /// = true  → 替换关于页面中的 Hiddify 品牌为 Xlink
  ///           包括 Logo、应用名称、版权信息等
  /// = false → 保留原版 Hiddify 品牌
  static const bool useXlinkBranding = true;

  /// 【自定义更新源】（预留，暂未实现）
  /// = true  → 使用 Xlink 自有更新服务器检查/下载更新
  ///           替代原版 GitHub Release 更新检查
  /// = false → 使用原版 Hiddify 更新机制
  static const bool useXlinkAppUpdate = true;
}
