import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hiddify/core/theme/app_theme_mode.dart';
import 'package:hiddify/core/theme/theme_extensions.dart';

// ---------------------------------------------------------------------------
//  "The Kinetic Aperture" — Light Color Scheme
// ---------------------------------------------------------------------------
const _kineticEtherLightScheme = ColorScheme(
  brightness: Brightness.light,

  // ── Primary (Kinetic Teal) ───────────────────────────────────────────
  primary: Color(0xFF006858), // primary
  onPrimary: Color(0xFFffffff), // on-primary
  primaryContainer: Color(0xFF00846f), // primary-container
  onPrimaryContainer: Color(0xFFffffff), // on-primary-container
  primaryFixed: Color(0xFF006858),
  primaryFixedDim: Color(0xFF005245),

  // ── Secondary ────────────────────────────────────────────────────────
  secondary: Color(0xFFbee9dc),
  onSecondary: Color(0xFF171d1b),
  secondaryContainer: Color(0xFFbee9dc), // secondary-container (Technical Data Chips)
  onSecondaryContainer: Color(0xFF436a60),

  // ── Tertiary ─────────────────────────────────────────────────────────
  tertiary: Color(0xFF5a6069),
  onTertiary: Color(0xFFffffff),
  tertiaryContainer: Color(0xFFe0e2ec),
  onTertiaryContainer: Color(0xFF171b21),

  // ── Error ────────────────────────────────────────────────────────────
  error: Color(0xFFba1a1a),
  onError: Color(0xFFffffff),
  errorContainer: Color(0xFFffdad6),
  onErrorContainer: Color(0xFF410002),

  // ── Surface hierarchy (Architectural layers) ─────────────────────────
  surface: Color(0xFFf5fbf7), // background / Level 0
  onSurface: Color(0xFF171d1b), // on-surface
  onSurfaceVariant: Color(0xFF6f7975), // on-surface-variant
  surfaceContainerLowest: Color(0xFFffffff), // cards/modules / Level 2
  surfaceContainerLow: Color(0xFFeff5f1), // sections / Level 1
  surfaceContainer: Color(0xFFffffff), // cards/modules
  surfaceContainerHigh: Color(0xFFe4e9e6), // inputs / active states
  surfaceContainerHighest: Color(0xFFe4e9e6), // inputs / active states
  // ── Outline ──────────────────────────────────────────────────────────
  outline: Color(0xFF6f7975), // outline
  outlineVariant: Color(0xFFbcc9c4), // outline-variant (ghost border)
  // ── Misc ─────────────────────────────────────────────────────────────
  surfaceTint: Color(0xFF006858),
  inverseSurface: Color(0xFF171d1b),
  onInverseSurface: Color(0xFFf5fbf7),
  inversePrimary: Color(0xFF00846f),
  shadow: Color(0x00000000), // no Material shadows
  scrim: Color(0xFF000000),
);

// ---------------------------------------------------------------------------
//  "Kinetic Ether" — Obsidian Dark Color Scheme
// ---------------------------------------------------------------------------
/// Hand-crafted dark [ColorScheme] following the Kinetic Ether design system.
/// Every value maps to a specific DESIGN.md token — see inline comments.
const _kineticEtherDarkScheme = ColorScheme(
  brightness: Brightness.dark,

  // ── Primary (Electric Teal) ──────────────────────────────────────────
  primary: Color(0xFF69d9c0), // primary
  onPrimary: Color(0xFF131313), // on-primary
  primaryContainer: Color(0xFF26a28b), // primary-container
  onPrimaryContainer: Color(0xFFC0F0E3), // on-primary-container
  primaryFixed: Color(0xFF69d9c0),
  primaryFixedDim: Color(0xFF4DB8A2), // primary-fixed-dim (icons)
  // ── Secondary (Deep Space Blue) ──────────────────────────────────────
  secondary: Color(0xFFb8c3ff), // secondary
  onSecondary: Color(0xFF131313),
  secondaryContainer: Color(0xFF3a4599), // secondary-container
  onSecondaryContainer: Color(0xFFdde1ff),

  // ── Tertiary ─────────────────────────────────────────────────────────
  tertiary: Color(0xFFd0bcff), // tertiary
  onTertiary: Color(0xFF131313),
  tertiaryContainer: Color(0xFF4f378b), // tertiary-container
  onTertiaryContainer: Color(0xFFeaddff),

  // ── Error ────────────────────────────────────────────────────────────
  error: Color(0xFFffb4ab),
  onError: Color(0xFF690005),
  errorContainer: Color(0xFF93000a),
  onErrorContainer: Color(0xFFffdad6),

  // ── Surface hierarchy (Obsidian tonal layers) ────────────────────────
  surface: Color(0xFF131313), // background / base layer
  onSurface: Color(0xFFe5e2e1), // on-surface (never #FFF!)
  onSurfaceVariant: Color(0xFFc4c7c5), // on-surface-variant
  surfaceContainerLowest: Color(0xFF0e0e0e),
  surfaceContainerLow: Color(0xFF1b1b1c), // structural sections
  surfaceContainer: Color(0xFF202020), // interactive cards
  surfaceContainerHigh: Color(0xFF2b2b2b),
  surfaceContainerHighest: Color(0xFF353535), // floating modals
  // ── Outline ──────────────────────────────────────────────────────────
  outline: Color(0xFF3d4945),
  outlineVariant: Color(0xFF3d4945), // ghost-border source
  // ── Misc ─────────────────────────────────────────────────────────────
  surfaceTint: Color(0xFF69d9c0), // surface-tint = primary
  inverseSurface: Color(0xFFe5e2e1),
  onInverseSurface: Color(0xFF131313),
  inversePrimary: Color(0xFF26a28b),
  shadow: Color(0x00000000), // no Material shadows
  scrim: Color(0xFF000000),
);

class AppTheme {
  AppTheme(this.mode, this.fontFamily);
  final AppThemeMode mode;
  final String fontFamily;

  // ── Light theme ── "The Digital Kineticist" ───────────────────────────
  ThemeData lightTheme(ColorScheme? lightColorScheme) {
    // Ignore system dynamic color in light mode — always use the custom scheme.
    final ColorScheme scheme = _kineticEtherLightScheme;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      fontFamily: fontFamily,

      // ── Extensions ──────────────────────────────────────────────────
      extensions: const <ThemeExtension<dynamic>>{ConnectionButtonTheme.light, KineticEtherTheme.light},

      // ── AppBar ── transparent, no shadow ─────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        iconTheme: IconThemeData(color: scheme.onSurface),
      ),

      // ── Card ── tonal layering, no Material shadow ───────────────────
      cardTheme: CardThemeData(
        color: scheme.surfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        surfaceTintColor: Colors.transparent,
      ),

      // ── Dialog / BottomSheet ─────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainer,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      ),

      // ── Navigation bar ───────────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),

      // ── Divider ── ghost border at low opacity ───────────────────────
      dividerTheme: DividerThemeData(color: scheme.outlineVariant.withValues(alpha: 0.25), thickness: 1),

      // ── Chip ─────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        selectedColor: scheme.secondaryContainer,
        side: BorderSide.none,
        shape: const StadiumBorder(),
      ),

      // ── ListTile ─────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        selectedTileColor: scheme.secondaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // ── PopupMenu ────────────────────────────────────────────────────
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surfaceContainer,
        elevation: 4, // Slight ambient shadow for floating menus
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // ── Switch ───────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.onPrimary;
          }
          return scheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary;
          }
          return scheme.surfaceContainerHighest;
        }),
      ),

      // ── SnackBar ─────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        contentTextStyle: TextStyle(color: scheme.onSurface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Dark theme  ── "Kinetic Ether" ────────────────────────────────────
  ThemeData darkTheme(ColorScheme? darkColorScheme) {
    // Ignore system dynamic color in dark mode — always use the custom scheme.
    final ColorScheme scheme = _kineticEtherDarkScheme;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: mode.trueBlack ? Colors.black : scheme.surface,
      fontFamily: fontFamily,

      // ── Extensions ──────────────────────────────────────────────────
      extensions: const <ThemeExtension<dynamic>>{ConnectionButtonTheme.dark, KineticEtherTheme.dark},

      // ── AppBar ── transparent, no shadow ─────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: mode.trueBlack ? Colors.black : scheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        iconTheme: IconThemeData(color: scheme.onSurface),
      ),

      // ── Card ── tonal layering, no Material shadow ───────────────────
      cardTheme: CardThemeData(
        color: scheme.surfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        surfaceTintColor: Colors.transparent,
      ),

      // ── Dialog / BottomSheet ─────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      ),

      // ── Navigation bar ───────────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),

      // ── Divider ── ghost border at low opacity ───────────────────────
      dividerTheme: DividerThemeData(color: scheme.outlineVariant.withValues(alpha: 0.15), thickness: 1),

      // ── Chip ─────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        selectedColor: scheme.primaryContainer,
        side: BorderSide.none,
        shape: const StadiumBorder(),
      ),

      // ── ListTile ─────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        selectedTileColor: scheme.primaryContainer.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // ── PopupMenu ────────────────────────────────────────────────────
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surfaceContainerHighest,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // ── Switch / Toggle ──────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.onPrimary;
          return scheme.onSurfaceVariant;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.primary;
          return scheme.surfaceContainerHighest;
        }),
      ),

      // ── Snackbar ─────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        contentTextStyle: TextStyle(color: scheme.onSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Cupertino theme (unchanged logic) ──────────────────────────────────
  CupertinoThemeData cupertinoThemeData(bool sysDark, ColorScheme? lightColorScheme, ColorScheme? darkColorScheme) {
    final bool isDark = switch (mode) {
      AppThemeMode.system => sysDark,
      AppThemeMode.light => false,
      AppThemeMode.dark => true,
      AppThemeMode.black => true,
    };
    final def = CupertinoThemeData(brightness: isDark ? Brightness.dark : Brightness.light);
    // final def = CupertinoThemeData(brightness: Brightness.dark);

    // return def;
    final defaultMaterialTheme = isDark ? darkTheme(darkColorScheme) : lightTheme(lightColorScheme);
    return MaterialBasedCupertinoThemeData(
      materialTheme: defaultMaterialTheme.copyWith(
        cupertinoOverrideTheme: def.copyWith(
          textTheme: CupertinoTextThemeData(
            textStyle: def.textTheme.textStyle.copyWith(fontFamily: fontFamily),
            actionTextStyle: def.textTheme.actionTextStyle.copyWith(fontFamily: fontFamily),
            navActionTextStyle: def.textTheme.navActionTextStyle.copyWith(fontFamily: fontFamily),
            navTitleTextStyle: def.textTheme.navTitleTextStyle.copyWith(fontFamily: fontFamily),
            navLargeTitleTextStyle: def.textTheme.navLargeTitleTextStyle.copyWith(fontFamily: fontFamily),
            pickerTextStyle: def.textTheme.pickerTextStyle.copyWith(fontFamily: fontFamily),
            dateTimePickerTextStyle: def.textTheme.dateTimePickerTextStyle.copyWith(fontFamily: fontFamily),
            tabLabelTextStyle: def.textTheme.tabLabelTextStyle.copyWith(fontFamily: fontFamily),
          ).copyWith(),
          barBackgroundColor: def.barBackgroundColor,
          scaffoldBackgroundColor: def.scaffoldBackgroundColor,
        ),
      ),
    );
  }
}
