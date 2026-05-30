import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/enums.dart';
import '../models/report_model.dart';

/// Akses koleksi `reports`. Satu-satunya tempat menyentuh Firestore untuk laporan.
class ReportRepository {
  final FirebaseFirestore _firestore;

  ReportRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('reports');

  /// Buat laporan baru, kembalikan id dokumen.
  Future<String> createReport(ReportModel report) async {
    final ref = await _col.add(report.toMap());
    return ref.id;
  }

  /// Stream laporan milik satu user, terbaru di atas.
  Stream<List<ReportModel>> watchReportsByUser(String uid) {
    return _col
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_mapSnapshot);
  }

  /// Ambil sekali daftar laporan milik user.
  Future<List<ReportModel>> getReportsByUser(String uid) async {
    final snap = await _col
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .get();
    return _mapSnapshot(snap);
  }

  Future<ReportModel?> getReportById(String id) async {
    final doc = await _col.doc(id).get();
    final data = doc.data();
    if (!doc.exists || data == null) return null;
    return ReportModel.fromMap(doc.id, data);
  }

  Future<void> updateStatus(String id, ReportStatus status) {
    return _col.doc(id).update({
      'status': status.value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteReport(String id) => _col.doc(id).delete();

  List<ReportModel> _mapSnapshot(QuerySnapshot<Map<String, dynamic>> snap) {
    return snap.docs
        .map((d) => ReportModel.fromMap(d.id, d.data()))
        .toList(growable: false);
  }
}
