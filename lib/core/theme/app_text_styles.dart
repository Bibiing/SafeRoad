import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Tipografi SafeRoad menggunakan Plus Jakarta Sans.
///
/// Hierarki:
/// - [heading] — judul besar (22px, bold).
/// - [title] — judul seksi (18px, semibold).
/// - [subtitle] — sub-judul card (15px, semibold).
/// - [body] — teks body standar (16px, regular).
/// - [caption] — metadata, timestamp (12px, regular, abu).
/// - [button] — label tombol (15px, semibold, putih).
/// - [badge] — label status pill (11px, semibold, putih).
class AppTextStyles {
  AppTextStyles._();

  static String? get _fontFamily =>
      GoogleFonts.plusJakartaSans().fontFamily;

  static TextStyle get heading => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  static TextStyle get title => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  static TextStyle get subtitle => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get body => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  static TextStyle get caption => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  static TextStyle get button => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.onPrimary,
      );

  static TextStyle get badge => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.onPrimary,
      );
}
