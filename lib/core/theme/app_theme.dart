import 'package:flutter/material.dart';
import 'colors.dart';
import 'typography.dart';
import 'spacing.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColorsExtension.light.primary,
      scaffoldBackgroundColor: AppColorsExtension.light.background,
      extensions: const <ThemeExtension<dynamic>>[
        AppColorsExtension.light,
      ],
      
      // Color Scheme
      colorScheme: ColorScheme.light(
        primary: AppColorsExtension.light.primary,
        secondary: AppColorsExtension.light.secondary,
        surface: AppColorsExtension.light.surface,
        error: AppColorsExtension.light.error,
        onPrimary: AppColorsExtension.light.surface,
        onSecondary: AppColorsExtension.light.surface,
        onSurface: AppColorsExtension.light.textPrimary,
        onError: AppColorsExtension.light.surface,
      ),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: AppTypography.display,
        headlineMedium: AppTypography.heading,
        titleLarge: AppTypography.subheading,
        bodyLarge: AppTypography.body,
        bodyMedium: AppTypography.caption, // often used as default secondary text
        labelSmall: AppTypography.label,
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: AppColorsExtension.light.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSpacing.cardRadius)),
          side: BorderSide(color: AppColorsExtension.light.border, width: 1), // Light border, no visible shadow
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColorsExtension.light.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
          borderSide: BorderSide(color: AppColorsExtension.light.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
          borderSide: BorderSide(color: AppColorsExtension.light.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
          borderSide: BorderSide(color: AppColorsExtension.light.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
          borderSide: BorderSide(color: AppColorsExtension.light.error),
        ),
        hintStyle: AppTypography.body.copyWith(color: AppColorsExtension.light.textSecondary),
      ),
      
      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColorsExtension.light.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColorsExtension.light.primary),
        titleTextStyle: AppTypography.heading,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: const Color(0xFFF9FAFB),
      scaffoldBackgroundColor: const Color(0xFF0F172A), // Dark slate/navy
      extensions: const <ThemeExtension<dynamic>>[
        AppColorsExtension.dark,
      ],
      
      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFF9FAFB),
        secondary: Color(0xFF9CA3AF),
        surface: Color(0xFF1E293B),
        error: Color(0xFFEF4444),
        onPrimary: Color(0xFF0F172A),
        onSecondary: Color(0xFF0F172A),
        onSurface: Color(0xFFF9FAFB),
        onError: Color(0xFFF9FAFB),
      ),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: AppTypography.display.copyWith(color: const Color(0xFFF9FAFB)),
        headlineMedium: AppTypography.heading.copyWith(color: const Color(0xFFF9FAFB)),
        titleLarge: AppTypography.subheading.copyWith(color: const Color(0xFFF9FAFB)),
        bodyLarge: AppTypography.body.copyWith(color: const Color(0xFFF9FAFB)),
        bodyMedium: AppTypography.caption.copyWith(color: const Color(0xFF9CA3AF)),
        labelSmall: AppTypography.label.copyWith(color: const Color(0xFF9CA3AF)),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: Color(0xFF1E293B),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSpacing.cardRadius)),
          side: BorderSide(color: Color(0xFF334155), width: 1),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E293B),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
          borderSide: const BorderSide(color: Color(0xFFF9FAFB)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        hintStyle: AppTypography.body.copyWith(color: const Color(0xFF9CA3AF)),
      ),
      
      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFFF9FAFB)),
        titleTextStyle: AppTypography.heading.copyWith(color: const Color(0xFFF9FAFB)),
      ),
    );
  }
}
