/// Nama-nama collection dan sub-collection di Firestore.
class FirestoreCollections {
  FirestoreCollections._();

  /// Koleksi utama user.
  static const String users = 'users';

  /// Koleksi utama laporan.
  static const String reports = 'reports';

  /// Sub-collection log status di bawah laporan.
  static const String statusLogs = 'statusLogs';
}
