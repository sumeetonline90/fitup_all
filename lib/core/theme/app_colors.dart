import 'package:flutter/material.dart';

/// Stitch / DESIGN.md — Neon Fluidic editorial palette.
abstract final class AppColors {
  AppColors._();

  /// Void background.
  static const Color background = Color(0xFF0E0E0E);

  /// Layer 1 — main content sections.
  static const Color surfaceContainer = Color(0xFF1A1919);

  /// Alias for surfaces (e.g. charts); same as [surfaceContainer].
  static const Color surface = surfaceContainer;

  /// Layer 2 — interactive cards base.
  static const Color surfaceContainerHigh = Color(0xFF201F1F);

  /// Layer 3 — tonal lift / tracks.
  static const Color surfaceContainerHighest = Color(0xFF262626);

  /// Primary — Electric Lime (headlines, positive emphasis).
  static const Color primary = Color(0xFFF3FFCA);

  /// Primary container — CTA fills, badges.
  static const Color primaryContainer = Color(0xFFCAFD00);

  /// Primary dim — glows, secondary emphasis on lime.
  static const Color primaryDim = Color(0xFFBEEE00);

  /// Secondary — Cyber Blue (AI, technical, activity accent).
  static const Color secondary = Color(0xFF00EEFC);

  /// Secondary dim.
  static const Color secondaryDim = Color(0xFF00DEEC);

  /// Tertiary — Hot Pink (alerts, wellbeing).
  static const Color tertiary = Color(0xFFFF6B9B);

  /// Tertiary container — deep pink accent.
  static const Color tertiaryContainer = Color(0xFFFF067F);

  /// Text primary on dark.
  static const Color onSurface = Color(0xFFFFFFFF);

  /// Primary text on [background] — alias of [onSurface] (design tokens).
  static const Color onBackground = onSurface;

  /// Body / secondary text.
  static const Color onSurfaceVariant = Color(0xFFADAAAA);

  /// Hairlines, inactive borders.
  static const Color outlineVariant = Color(0xFF484847);

  /// Error states.
  static const Color error = Color(0xFFFF7351);

  /// Warning / focus callouts (amber).
  static const Color warningAmber = Color(0xFFFFB74D);

  /// Cyber Blue at 15% — neon shadow tint (use with blur).
  static Color get neonGlow => const Color(0xFF00EEFC).withValues(alpha: 0.15);

  /// Ghost border for glass cards (white 10%).
  static Color get glassBorder => const Color(0xFFFFFFFF).withValues(alpha: 0.10);

  /// Legacy alias: primary electric lime gradient start.
  static const Color primaryFixed = primary;

  /// Fluid CTA gradient (primary → container).
  static const LinearGradient primaryGradient = LinearGradient(
    colors: <Color>[primary, primaryContainer],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Secondary → primary progress / charts.
  static const LinearGradient secondaryToPrimaryGradient = LinearGradient(
    colors: <Color>[secondary, primaryContainer],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const Color textPrimary = onSurface;
  static const Color textSecondary = onSurfaceVariant;
  static const Color textTertiary = onSurfaceVariant;

  // --- Backwards compatibility for older widget code ---
  static const Color neonCyan = secondary;
  static const Color cardBackground = surfaceContainer;
  static const Color inactive = onSurfaceVariant;
  static const Color electricBlue = secondary;
  static const Color successGreen = primaryContainer;
  static const Color magenta = tertiary;
}
