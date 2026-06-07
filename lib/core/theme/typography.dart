import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  static TextStyle get _base => GoogleFonts.inter(
        letterSpacing: -0.2, // Inter looks slightly better with tight tracking
      );

  static TextStyle get display => _base.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.8,
        height: 1.2,
      );

  static TextStyle get heading => _base.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        height: 1.2,
      );

  static TextStyle get subheading => _base.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        height: 1.3,
      );

  static TextStyle get body => _base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.5,
      );

  static TextStyle get caption => _base.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
      );

  static TextStyle get label => _base.copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        height: 1.4,
      );
}
