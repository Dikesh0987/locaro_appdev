import 'package:flutter/material.dart';

class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color primary;
  final Color secondary;
  final Color background;
  final Color surface;
  final Color border;
  final Color offerOrange;
  final Color success;
  final Color error;
  final Color textPrimary;
  final Color textSecondary;

  const AppColorsExtension({
    required this.primary,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.border,
    required this.offerOrange,
    required this.success,
    required this.error,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  ThemeExtension<AppColorsExtension> copyWith({
    Color? primary,
    Color? secondary,
    Color? background,
    Color? surface,
    Color? border,
    Color? offerOrange,
    Color? success,
    Color? error,
    Color? textPrimary,
    Color? textSecondary,
  }) {
    return AppColorsExtension(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      border: border ?? this.border,
      offerOrange: offerOrange ?? this.offerOrange,
      success: success ?? this.success,
      error: error ?? this.error,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
    );
  }

  @override
  ThemeExtension<AppColorsExtension> lerp(ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) {
      return this;
    }
    return AppColorsExtension(
      primary: Color.lerp(primary, other.primary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      border: Color.lerp(border, other.border, t)!,
      offerOrange: Color.lerp(offerOrange, other.offerOrange, t)!,
      success: Color.lerp(success, other.success, t)!,
      error: Color.lerp(error, other.error, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
    );
  }

  static const light = AppColorsExtension(
    primary: Color(0xFF0B1736),
    secondary: Color(0xFF6B7280),
    background: Color(0xFFFAFAFA),
    surface: Color(0xFFFFFFFF),
    border: Color(0xFFF3F4F6),
    offerOrange: Color(0xFFF97316),
    success: Color(0xFF10B981),
    error: Color(0xFFEF4444),
    textPrimary: Color(0xFF111827),
    textSecondary: Color(0xFF6B7280),
  );

  static const dark = AppColorsExtension(
    primary: Color(0xFFF9FAFB),
    secondary: Color(0xFF9CA3AF),
    background: Color(0xFF0F172A),
    surface: Color(0xFF1E293B),
    border: Color(0xFF334155),
    offerOrange: Color(0xFFF97316),
    success: Color(0xFF10B981),
    error: Color(0xFFEF4444),
    textPrimary: Color(0xFFF9FAFB),
    textSecondary: Color(0xFF9CA3AF),
  );
}

extension BuildContextColors on BuildContext {
  AppColorsExtension get colors => Theme.of(this).extension<AppColorsExtension>() ?? AppColorsExtension.light;
}
