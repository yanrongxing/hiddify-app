/// Feature flags for Xlink customization.
///
/// These flags control which features are enabled/disabled
/// in the customized version of the app.
/// Toggle these to switch between original and customized behavior.
class FeatureFlags {
  const FeatureFlags._();

  /// When true, the app requires Xlink login before accessing any feature.
  /// The intro page becomes a login/register flow instead of the original
  /// language/region selection + TOS acceptance.
  static const bool enableXlinkAuth = true;

  /// When true, hides advanced settings that end users don't need:
  /// DNS options, Inbound options, TLS Tricks, WARP options.
  static const bool hideAdvancedSettings = true;

  /// When true, shows subscription plan purchase UI.
  static const bool enableSubscriptionShop = true;

  /// When true, hides the manual "Add Profile" button on the home page.
  /// Profiles are managed automatically via Xboard subscription sync.
  static const bool hideManualProfileAdd = true;

  /// When true, hides Per-App Proxy from settings.
  static const bool hidePerAppProxy = false;

  /// When true, hides Route Rules from settings.
  static const bool hideRouteRules = false;

  /// When true, replaces the About page branding with Xlink branding.
  static const bool useXlinkBranding = true;

  /// When true, replaces the app update mechanism with Xlink's own.
  static const bool useXlinkAppUpdate = true;
}
