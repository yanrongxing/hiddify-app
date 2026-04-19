import 'dart:ui';

import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Connection Button Theme
// ---------------------------------------------------------------------------
class ConnectionButtonTheme extends ThemeExtension<ConnectionButtonTheme> {
  const ConnectionButtonTheme({this.idleColor, this.connectedColor});

  final Color? idleColor;
  final Color? connectedColor;

  /// Light variant – Kinetic Aperture
  static const ConnectionButtonTheme light = ConnectionButtonTheme(
    idleColor: Color(0xFFbcc9c4),      // outline-variant
    connectedColor: Color(0xFF006858), // primary
  );

  /// Dark variant – teal-accented, following the Kinetic Ether palette.
  static const ConnectionButtonTheme dark = ConnectionButtonTheme(
    idleColor: Color(0xFF3d4945),      // outline-variant / muted teal
    connectedColor: Color(0xFF26a28b), // primary-container teal
  );

  @override
  ThemeExtension<ConnectionButtonTheme> copyWith({Color? idleColor, Color? connectedColor}) => ConnectionButtonTheme(
    idleColor: idleColor ?? this.idleColor,
    connectedColor: connectedColor ?? this.connectedColor,
  );

  @override
  ThemeExtension<ConnectionButtonTheme> lerp(covariant ThemeExtension<ConnectionButtonTheme>? other, double t) {
    if (other is! ConnectionButtonTheme) {
      return this;
    }
    return ConnectionButtonTheme(
      idleColor: Color.lerp(idleColor, other.idleColor, t),
      connectedColor: Color.lerp(connectedColor, other.connectedColor, t),
    );
  }
}

// ---------------------------------------------------------------------------
// Kinetic Ether Theme  –  "The Digital Kineticist" design-system extension
// ---------------------------------------------------------------------------
/// Holds design tokens that cannot be expressed through [ColorScheme] alone,
/// such as gradients, glassmorphism parameters, and ambient glow settings.
class KineticEtherTheme extends ThemeExtension<KineticEtherTheme> {
  const KineticEtherTheme({
    required this.gradientPrimary,
    required this.gradientSecondary,
    required this.ambientShadowColor,
    required this.ghostBorderColor,
    required this.glassBackground,
    required this.glassSigma,
  });

  /// CTA "soul" gradient: primary → primary-container @ 135°.
  final LinearGradient gradientPrimary;

  /// Secure-tunnel gradient: secondary → tertiary.
  final LinearGradient gradientSecondary;

  /// Ambient shadow using surface-tint at 6 % opacity.
  final Color ambientShadowColor;

  /// Ghost border: outline-variant at 15 % opacity.
  final Color ghostBorderColor;

  /// Glass fill: surface-variant at 40 % opacity.
  final Color glassBackground;

  /// Backdrop-blur sigma (20–40 px mapped to logical).
  final double glassSigma;

  // ── Dark preset ──────────────────────────────────────────────────────
  static const KineticEtherTheme dark = KineticEtherTheme(
    gradientPrimary: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF69d9c0), Color(0xFF26a28b)],
    ),
    gradientSecondary: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFb8c3ff), Color(0xFFd0bcff)],
    ),
    ambientShadowColor: Color(0x0F69d9c0), // 6 % opacity
    ghostBorderColor: Color(0x263d4945),    // 15 % opacity
    glassBackground: Color(0x66353535),     // 40 % opacity
    glassSigma: 24.0,
  );

  // ── Light preset (The Kinetic Aperture) ──────────────────────────────
  static const KineticEtherTheme light = KineticEtherTheme(
    gradientPrimary: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF006858), Color(0xFF00846f)],
    ),
    gradientSecondary: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFbee9dc), Color(0xFF8bcbbb)], // secondary to secondary-container tint
    ),
    ambientShadowColor: Color(0x0D171d1b), // 5 % opacity of on-surface
    ghostBorderColor: Color(0x26bcc9c4),    // 15 % opacity of outline-variant
    glassBackground: Color(0xCCf5fbf7),     // 80 % opacity of surface
    glassSigma: 20.0,
  );

  @override
  ThemeExtension<KineticEtherTheme> copyWith({
    LinearGradient? gradientPrimary,
    LinearGradient? gradientSecondary,
    Color? ambientShadowColor,
    Color? ghostBorderColor,
    Color? glassBackground,
    double? glassSigma,
  }) =>
      KineticEtherTheme(
        gradientPrimary: gradientPrimary ?? this.gradientPrimary,
        gradientSecondary: gradientSecondary ?? this.gradientSecondary,
        ambientShadowColor: ambientShadowColor ?? this.ambientShadowColor,
        ghostBorderColor: ghostBorderColor ?? this.ghostBorderColor,
        glassBackground: glassBackground ?? this.glassBackground,
        glassSigma: glassSigma ?? this.glassSigma,
      );

  @override
  ThemeExtension<KineticEtherTheme> lerp(covariant ThemeExtension<KineticEtherTheme>? other, double t) {
    if (other is! KineticEtherTheme) return this;
    return KineticEtherTheme(
      gradientPrimary: LinearGradient.lerp(gradientPrimary, other.gradientPrimary, t)!,
      gradientSecondary: LinearGradient.lerp(gradientSecondary, other.gradientSecondary, t)!,
      ambientShadowColor: Color.lerp(ambientShadowColor, other.ambientShadowColor, t)!,
      ghostBorderColor: Color.lerp(ghostBorderColor, other.ghostBorderColor, t)!,
      glassBackground: Color.lerp(glassBackground, other.glassBackground, t)!,
      glassSigma: lerpDouble(glassSigma, other.glassSigma, t)!,
    );
  }
}
