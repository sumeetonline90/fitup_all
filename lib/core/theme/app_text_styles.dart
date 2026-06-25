import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Space Grotesk (display/headlines) + Manrope (body/labels) — see DESIGN.md.
abstract final class AppTextStyles {
  AppTextStyles._();

  /// Display large — 3.5rem, 700, -0.02em, Space Grotesk.
  static TextStyle get displayLarge => GoogleFonts.spaceGrotesk(
        fontSize: 56,
        fontWeight: FontWeight.w700,
        height: 1.1,
        letterSpacing: -0.02 * 16,
        color: AppColors.onSurface,
      );

  /// Headline large — 2rem, 700, Space Grotesk.
  static TextStyle get headlineLarge => GoogleFonts.spaceGrotesk(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: AppColors.onSurface,
      );

  /// Headline medium — 1.5rem, 600, Space Grotesk.
  static TextStyle get headlineMedium => GoogleFonts.spaceGrotesk(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.25,
        color: AppColors.onSurface,
      );

  /// Body large — 1rem, 400, Manrope.
  static TextStyle get bodyLarge => GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.onSurface,
      );

  /// Body medium — 0.875rem, 400, Manrope.
  static TextStyle get bodyMedium => GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: AppColors.onSurfaceVariant,
      );

  /// Label small — 0.75rem, 500, Manrope.
  static TextStyle get labelSmall => GoogleFonts.manrope(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.35,
        letterSpacing: 0.02,
        color: AppColors.onSurfaceVariant,
      );

  /// H1 / welcome screens (slightly smaller than displayLarge for mobile).
  static TextStyle get h1 => GoogleFonts.spaceGrotesk(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        height: 1.15,
        letterSpacing: -0.02 * 16,
        color: AppColors.onSurface,
      );

  static TextStyle get h2 => headlineLarge;
  static TextStyle get h3 => headlineMedium;

  static TextStyle get bodySmall => GoogleFonts.manrope(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: AppColors.onSurfaceVariant,
      );

  /// Buttons / chips (slightly larger than [label]).
  static TextStyle get labelLarge => GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.35,
        letterSpacing: 0.02,
        color: AppColors.onSurface,
      );

  static TextStyle get label => GoogleFonts.manrope(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.08,
        color: AppColors.secondary,
      );

  static TextStyle get button => GoogleFonts.spaceGrotesk(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.02,
      );
}
