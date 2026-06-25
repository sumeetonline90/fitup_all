import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

/// Global dark theme aligned with Stitch / DESIGN.md.
abstract final class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    const ColorScheme scheme = ColorScheme.dark(
      surface: AppColors.background,
      primary: AppColors.primary,
      onPrimary: Color(0xFF516700),
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: Color(0xFF4A5E00),
      secondary: AppColors.secondary,
      onSecondary: Color(0xFF005359),
      secondaryContainer: AppColors.secondaryDim,
      tertiary: AppColors.tertiary,
      onTertiary: Color(0xFF47001F),
      error: AppColors.error,
      onSurface: AppColors.onSurface,
      onSurfaceVariant: AppColors.onSurfaceVariant,
      outline: AppColors.outlineVariant,
      outlineVariant: AppColors.outlineVariant,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background.withValues(alpha: 0.8),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.headlineMedium,
        iconTheme: const IconThemeData(color: AppColors.onSurface),
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge,
        displayMedium: AppTextStyles.headlineLarge,
        displaySmall: AppTextStyles.headlineMedium,
        headlineLarge: AppTextStyles.headlineLarge,
        headlineMedium: AppTextStyles.headlineMedium,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelSmall: AppTextStyles.labelSmall,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.secondary,
        unselectedItemColor: AppColors.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showSelectedLabels: false,
        showUnselectedLabels: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.background,
        indicatorColor: AppColors.secondary.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.all(AppTextStyles.labelSmall),
        iconTheme: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.secondary, size: 28);
          }
          return const IconThemeData(color: AppColors.onSurfaceVariant, size: 26);
        }),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.outlineVariant.withValues(alpha: 0.3),
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceContainerHigh,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.onSurface),
        behavior: SnackBarBehavior.floating,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF000000),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.5),
          ),
        ),
        labelStyle: AppTextStyles.labelSmall,
      ),
    );
  }
}
