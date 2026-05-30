// Enum & helper untuk domain SafeRoad.
// Murni data + pemetaan ke string yang disimpan di Firestore. Tanpa import
// widget Flutter — pemetaan warna status ditaruh di layer View.

/// Kategori kerusakan yang bisa dilaporkan user.
enum ReportCategory {
  lubang,
  lampuJalan,
  rambu,
  marka;

  /// Label tampilan dalam Bahasa Indonesia.
  String get label {
    switch (this) {
      case ReportCategory.lubang:
        return 'Lubang Jalan';
      case ReportCategory.lampuJalan:
        return 'Lampu Jalan Rusak';
      case ReportCategory.rambu:
        return 'Rambu Rusak';
      case ReportCategory.marka:
        return 'Marka Jalan';
    }
  }

  /// Nilai yang disimpan di Firestore.
  String get value => name;

  static ReportCategory fromValue(String? value) {
    return ReportCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ReportCategory.lubang,
    );
  }
}

/// Status perbaikan sebuah laporan.
enum ReportStatus {
  pending,
  diverifikasi,
  diproses,
  selesai,
  ditolak;

  String get label {
    switch (this) {
      case ReportStatus.pending:
        return 'Menunggu';
      case ReportStatus.diverifikasi:
        return 'Diverifikasi';
      case ReportStatus.diproses:
        return 'Diproses';
      case ReportStatus.selesai:
        return 'Selesai';
      case ReportStatus.ditolak:
        return 'Ditolak';
    }
  }

  String get value => name;

  static ReportStatus fromValue(String? value) {
    return ReportStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ReportStatus.pending,
    );
  }
}

/// Peran pengguna: user biasa atau admin.
enum UserRole {
  user,
  admin;

  String get value => name;

  static UserRole fromValue(String? value) {
    return UserRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => UserRole.user,
    );
  }
}
