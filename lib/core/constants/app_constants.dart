/// Konstanta umum aplikasi SafeRoad.
class AppConstants {
  AppConstants._();

  /// Nama aplikasi.
  static const String appName = 'SafeRoad';

  /// Tagline.
  static const String appTagline =
      'Laporkan kerusakan jalan & fasilitas publik';

  /// Kualitas kompresi foto (0–100).
  static const int imageQuality = 70;

  /// Maksimum jumlah foto per laporan (dibatasi 1 foto per laporan).
  static const int maxReportPhotos = 1;

  /// OAuth 2.0 **Web client ID** (server client ID) untuk Google Sign-In.
  ///
  /// Di-hardcode agar `flutter run` langsung berfungsi tanpa `--dart-define`.
  /// Diperlukan di **Android** agar `idToken` tersedia; di iOS client ID juga
  /// dibaca dari `GoogleService-Info.plist` (`GIDClientID`).
  ///
  /// Nilai berasal dari OAuth Web client (client_type 3) project Firebase
  /// `saferoad-643a9` (lihat `android/app/google-services.json`).
  static const String googleServerClientId =
      '8415063511-duu4cvb6b7ao65hu1reqbf7q40bipnso.apps.googleusercontent.com';

  /// Label navigasi bawah.
  static const String navHome = 'Beranda';
  static const String navMap = 'Peta';
  static const String navMyReports = 'Laporan Saya';
  static const String navProfile = 'Profil';
}
