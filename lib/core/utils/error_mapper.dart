import 'package:firebase_auth/firebase_auth.dart';

/// Mengubah berbagai jenis error menjadi pesan Bahasa Indonesia yang ramah
/// untuk ditampilkan ke pengguna.
///
/// Util bersama lintas modul — menggantikan helper privat `_extractMessage`
/// yang sebelumnya diduplikasi di ~9 ViewModel, dan `e.toString()` mentah
/// di ViewModel Admin (audit masalah #3 & #6).
///
/// Catatan arsitektur: util ini sengaja mengenal tipe exception Firebase
/// agar pemetaan kode error akurat. Ini util di `core/utils` (bukan
/// View/ViewModel), sehingga ViewModel tetap bersih dari impor Firebase
/// langsung dan kepatuhan MVVM terjaga.
String mapErrorToMessage(Object error) {
  if (error is FirebaseAuthException) {
    return _authMessage(error.code);
  }
  if (error is FirebaseException) {
    return _firebaseMessage(error.code);
  }

  // Exception milik aplikasi sendiri umumnya sudah berisi pesan Bahasa
  // Indonesia yang ramah (mis. "Layanan lokasi tidak aktif"). Cukup buang
  // prefix "Exception: " bawaan Dart.
  final text = error.toString();
  const prefix = 'Exception: ';
  if (text.startsWith(prefix)) {
    final cleaned = text.substring(prefix.length).trim();
    if (cleaned.isNotEmpty) return cleaned;
  }

  // Fallback generik bila pesan tidak dikenal / terlihat teknis.
  if (text.isEmpty || text.startsWith('[') || text.contains('Instance of')) {
    return 'Terjadi kesalahan. Coba lagi.';
  }
  return text;
}

/// Pemetaan kode FirebaseAuth → pesan ramah.
String _authMessage(String code) {
  switch (code) {
    case 'invalid-email':
      return 'Format email tidak valid.';
    case 'user-disabled':
      return 'Akun ini telah dinonaktifkan.';
    case 'user-not-found':
      return 'Akun tidak ditemukan.';
    case 'wrong-password':
      return 'Kata sandi salah.';
    case 'invalid-credential':
      return 'Email atau kata sandi salah.';
    case 'email-already-in-use':
      return 'Email telah digunakan. Silakan masuk atau gunakan email lain.';
    case 'account-exists-with-different-credential':
      return 'Email telah digunakan dengan metode masuk lain. '
          'Coba masuk memakai email & kata sandi.';
    case 'credential-already-in-use':
      return 'Akun Google ini sudah terhubung dengan pengguna lain.';
    case 'weak-password':
      return 'Kata sandi terlalu lemah (minimal 6 karakter).';
    case 'operation-not-allowed':
      return 'Metode login ini sedang tidak diizinkan.';
    case 'too-many-requests':
      return 'Terlalu banyak percobaan. Coba lagi nanti.';
    case 'network-request-failed':
      return 'Gagal terhubung ke jaringan. Periksa koneksi internet.';
    default:
      return 'Terjadi kesalahan autentikasi. Coba lagi.';
  }
}

/// Pemetaan kode FirebaseException (Firestore/Storage/dll) → pesan ramah.
String _firebaseMessage(String code) {
  switch (code) {
    case 'permission-denied':
      return 'Akses ditolak. Anda tidak memiliki izin untuk tindakan ini.';
    case 'unavailable':
      return 'Layanan sedang tidak tersedia. Coba lagi nanti.';
    case 'not-found':
      return 'Data tidak ditemukan.';
    case 'already-exists':
      return 'Data sudah ada.';
    case 'cancelled':
      return 'Operasi dibatalkan.';
    case 'deadline-exceeded':
      return 'Permintaan melebihi batas waktu. Coba lagi.';
    case 'resource-exhausted':
      return 'Kuota layanan habis. Coba lagi nanti.';
    case 'unauthenticated':
      return 'Sesi berakhir. Silakan masuk kembali.';
    default:
      return 'Terjadi kesalahan pada server. Coba lagi.';
  }
}
