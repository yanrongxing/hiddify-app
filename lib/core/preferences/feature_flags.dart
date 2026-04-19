/// Feature flags for Xlink customization.
///
/// These flags control which features are enabled/disabled
/// in the customized version of the app.
/// Toggle these to switch between original and customized behavior.
class FeatureFlags {
  const FeatureFlags._();

  /// When true, enables Xlink auth module (login/register pages available).
  /// Guests can use the app freely (browse, connect VPN, etc.).
  /// Login is only required when accessing user profile / personal center.
  static const bool enableXlinkAuth = false;

  /// When true, hides advanced settings that end users don't need:
  /// DNS options, Inbound options, TLS Tricks, WARP options.
  static const bool hideAdvancedSettings = false;

  /// When true, shows subscription plan purchase UI.
  static const bool enableSubscriptionShop = false;

  /// When true, hides the manual "Add Profile" button on the home page.
  /// Profiles are managed automatically via Xboard subscription sync.
  static const bool hideManualProfileAdd = false;

  /// When true, hides Per-App Proxy from settings.
  static const bool hidePerAppProxy = false;

  /// When true, hides Route Rules from settings.
  static const bool hideRouteRules = false;

  /// When true, replaces the About page branding with Xlink branding.
  static const bool useXlinkBranding = false;

  /// When true, replaces the app update mechanism with Xlink's own.
  static const bool useXlinkAppUpdate = false;
}
