/// Enumerasi domain SafeRoad.
///
/// Tiap enum menyediakan:
/// - [label] — teks tampilan dalam Bahasa Indonesia.
/// - [toFirestore] — nilai string untuk disimpan ke Firestore.
/// - Static factory [fromFirestore] — parse balik dari string.
library;

// ---------------------------------------------------------------------------
// User Role
// ---------------------------------------------------------------------------

/// Peran pengguna dalam sistem.
enum UserRole {
  user,
  admin;

  /// Label Bahasa Indonesia.
  String get label {
    switch (this) {
      case UserRole.user:
        return 'Pengguna';
      case UserRole.admin:
        return 'Admin';
    }
  }

  /// Nilai yang disimpan ke Firestore.
  String get toFirestore => name;

  /// Parse dari string Firestore. Default [UserRole.user] bila tidak dikenal.
  static UserRole fromFirestore(String? value) {
    return UserRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => UserRole.user,
    );
  }
}

// ---------------------------------------------------------------------------
// Report Category
// ---------------------------------------------------------------------------

/// Kategori kerusakan / fasilitas publik yang bisa dilaporkan.
enum ReportCategory {
  pothole,
  streetLight,
  trafficSign,
  roadMarking,
  other;

  /// Label Bahasa Indonesia.
  String get label {
    switch (this) {
      case ReportCategory.pothole:
        return 'Lubang Jalan';
      case ReportCategory.streetLight:
        return 'Lampu Jalan';
      case ReportCategory.trafficSign:
        return 'Rambu Lalu Lintas';
      case ReportCategory.roadMarking:
        return 'Marka Jalan';
      case ReportCategory.other:
        return 'Lainnya';
    }
  }

  String get toFirestore => name;

  static ReportCategory fromFirestore(String? value) {
    return ReportCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ReportCategory.other,
    );
  }
}

// ---------------------------------------------------------------------------
// Report Status
// ---------------------------------------------------------------------------

/// Status alur perbaikan laporan.
///
/// ```
/// pending → verified → inProgress → completed
///                    ↘ rejected
/// ```
enum ReportStatus {
  pending,
  verified,
  inProgress,
  completed,
  rejected;

  /// Label Bahasa Indonesia.
  String get label {
    switch (this) {
      case ReportStatus.pending:
        return 'Menunggu';
      case ReportStatus.verified:
        return 'Diverifikasi';
      case ReportStatus.inProgress:
        return 'Diproses';
      case ReportStatus.completed:
        return 'Selesai';
      case ReportStatus.rejected:
        return 'Ditolak';
    }
  }

  String get toFirestore => name;

  static ReportStatus fromFirestore(String? value) {
    return ReportStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ReportStatus.pending,
    );
  }

  /// Poin kontribusi yang telah diperoleh dari laporan dengan status ini.
  int get pointsEarned {
    switch (this) {
      case ReportStatus.pending:
      case ReportStatus.rejected:
        return 10;
      case ReportStatus.verified:
      case ReportStatus.inProgress:
        return 15;
      case ReportStatus.completed:
        return 40;
    }
  }
}
