import 'package:flutter/material.dart';

/// Palet warna SafeRoad.
///
/// Tema hijau (SDG 9 & 11 — lingkungan, community).
/// Warna status menjadi bahasa visual utama untuk state laporan.
class AppColors {
  AppColors._();

  // ── Primary ──────────────────────────────────────────────────────────
  /// Hijau utama SafeRoad.
  static const Color primary = Color(0xFF639922);

  /// Hijau gelap — untuk elemen ditekan/aktif.
  static const Color primaryDark = Color(0xFF3B6D11);

  /// Hijau muda transparan — surface terpilih, highlight.
  static const Color primaryTint = Color(0xFFEAF3DE);

  // ── Netral ───────────────────────────────────────────────────────────
  /// Latar belakang utama (off-white).
  static const Color background = Color(0xFFF7F7F5);

  /// Surface kartu.
  static const Color surface = Color(0xFFFFFFFF);

  /// Border halus.
  static const Color border = Color(0xFFE5E5E3);

  /// Divider.
  static const Color divider = Color(0xFFEEEEEC);

  // ── Teks ─────────────────────────────────────────────────────────────
  /// Teks utama (judul, body).
  static const Color textPrimary = Color(0xFF1A1A1A);

  /// Teks sekunder (caption, metadata).
  static const Color textSecondary = Color(0xFF6B6B6B);

  /// Teks hint / placeholder.
  static const Color textHint = Color(0xFF9E9E9E);

  /// Teks di atas warna primer.
  static const Color onPrimary = Color(0xFFFFFFFF);

  // ── Status Laporan ───────────────────────────────────────────────────
  /// Menunggu — abu.
  static const Color statusPending = Color(0xFF888780);

  /// Diverifikasi — biru.
  static const Color statusVerified = Color(0xFF378ADD);

  /// Diproses — amber/oranye.
  static const Color statusInProgress = Color(0xFFBA7517);

  /// Selesai — hijau (sama dengan primary).
  static const Color statusCompleted = Color(0xFF639922);

  /// Ditolak — merah.
  static const Color statusRejected = Color(0xFFE24B4A);

  // ── Feedback ─────────────────────────────────────────────────────────
  static const Color error = Color(0xFFE24B4A);
  static const Color success = Color(0xFF639922);
  static const Color warning = Color(0xFFBA7517);
}
