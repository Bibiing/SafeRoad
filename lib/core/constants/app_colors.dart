import 'package:flutter/material.dart';

/// Palet warna SafeRoad — gaya CLASSIC/FLAT, warna solid, tanpa gradien.
/// Satu warna primer, abu-abu netral untuk teks/border, putih untuk background.
class AppColors {
  AppColors._();

  // Primer
  static const Color primary = Color(0xFF1565C0);
  static const Color primaryDark = Color(0xFF0D47A1);

  // Netral
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF5F6F8);
  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFEEEEEE);

  // Teks
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF616161);
  static const Color textHint = Color(0xFF9E9E9E);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Status (hanya dipakai untuk badge status laporan)
  static const Color statusPending = Color(0xFF9E9E9E);
  static const Color statusVerified = Color(0xFF1565C0);
  static const Color statusInProgress = Color(0xFFEF6C00);
  static const Color statusDone = Color(0xFF2E7D32);
  static const Color statusRejected = Color(0xFFC62828);

  // Feedback
  static const Color error = Color(0xFFC62828);
}
