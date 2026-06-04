import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTypography {
  AppTypography._();

  static TextStyle get _base => GoogleFonts.inter(
        color: AppColors.textPrimary,
        letterSpacing: -0.2, // Inter looks slightly better with tight tracking
      );

  static TextStyle get display => _base.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.2,
      );

  static TextStyle get heading => _base.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.2,
      );

  static TextStyle get subheading => _base.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.3,
      );

  static TextStyle get body => _base.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.5,
      );

  static TextStyle get caption => _base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.4,
      );

  static TextStyle get label => _base.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.4,
      );
}
