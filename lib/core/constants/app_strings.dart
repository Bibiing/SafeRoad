/// Teks statis aplikasi (Bahasa Indonesia). Hindari hardcode string di widget.
class AppStrings {
  AppStrings._();

  static const String appName = 'SafeRoad';
  static const String appTagline =
      'Laporkan kerusakan jalan & fasilitas publik';

  // Auth
  static const String login = 'Masuk';
  static const String register = 'Daftar';
  static const String logout = 'Keluar';
  static const String email = 'Email';
  static const String password = 'Kata Sandi';
  static const String name = 'Nama Lengkap';
  static const String noAccount = 'Belum punya akun? Daftar';
  static const String haveAccount = 'Sudah punya akun? Masuk';

  // Laporan
  static const String myReports = 'Laporan Saya';
  static const String newReport = 'Laporan Baru';
  static const String reportDetail = 'Detail Laporan';
  static const String title = 'Judul';
  static const String description = 'Deskripsi';
  static const String category = 'Kategori';
  static const String status = 'Status';
  static const String location = 'Lokasi';
  static const String photo = 'Foto';
  static const String addPhoto = 'Tambah Foto';
  static const String pickPhotoTitle = 'Pilih Sumber Foto';
  static const String camera = 'Kamera';
  static const String gallery = 'Galeri';
  static const String useCurrentLocation = 'Gunakan Lokasi Saat Ini';
  static const String submit = 'Kirim Laporan';
  static const String delete = 'Hapus';
  static const String cancel = 'Batal';

  // State kosong & error
  static const String emptyReports =
      'Belum ada laporan. Buat laporan pertamamu.';
  static const String genericError = 'Terjadi kesalahan. Coba lagi.';
  static const String requiredField = 'Wajib diisi';
  static const String invalidEmail = 'Format email tidak valid';
  static const String shortPassword = 'Kata sandi minimal 6 karakter';
}
