import 'package:cloud_firestore/cloud_firestore.dart';

import 'dto/report_dto.dart';
import 'dto/report_status_log_dto.dart';

/// Abstraksi data source laporan (Firestore).
abstract class ReportRemoteDataSource {
  /// Buat laporan baru, kembalikan ID dokumen.
  Future<String> createReport(ReportDto dto);

  /// Update laporan yang sudah ada.
  Future<void> updateReport(ReportDto dto);

  /// Hapus dokumen laporan.
  Future<void> deleteReport(String id);

  /// Ambil laporan berdasarkan ID.
  Future<ReportDto?> getReportById(String id);

  /// Stream realtime satu laporan (untuk layar detail).
  Stream<ReportDto?> watchReport(String id);

  /// Ambil semua laporan milik [userId].
  Future<List<ReportDto>> getReportsByUser(String userId);

  /// Ambil semua laporan.
  Future<List<ReportDto>> getAllReports();

  /// Stream realtime semua laporan.
  Stream<List<ReportDto>> watchAllReports();

  /// Ambil status log untuk laporan [reportId].
  Future<List<ReportStatusLogDto>> getStatusLogs(String reportId);

  /// Tambah entri status log ke sub-collection `statusLogs`.
  Future<void> addStatusLog(ReportStatusLogDto dto);
}

/// Implementasi [ReportRemoteDataSource] menggunakan Cloud Firestore.
class FirestoreReportRemoteDataSource implements ReportRemoteDataSource {
  final FirebaseFirestore _firestore;

  FirestoreReportRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _reports =>
      _firestore.collection('reports');

  @override
  Future<String> createReport(ReportDto dto) async {
    final ref = await _reports.add(dto.toFirestore());
    return ref.id;
  }

  @override
  Future<void> updateReport(ReportDto dto) {
    return _reports.doc(dto.id).update(dto.toUpdateMap());
  }

  @override
  Future<void> deleteReport(String id) => _reports.doc(id).delete();

  @override
  Future<ReportDto?> getReportById(String id) async {
    final doc = await _reports.doc(id).get();
    final data = doc.data();
    if (!doc.exists || data == null) return null;
    return ReportDto.fromFirestore(doc.id, data);
  }

  @override
  Stream<ReportDto?> watchReport(String id) {
    return _reports.doc(id).snapshots().map((doc) {
      final data = doc.data();
      if (!doc.exists || data == null) return null;
      return ReportDto.fromFirestore(doc.id, data);
    });
  }

  @override
  Future<List<ReportDto>> getReportsByUser(String userId) async {
    final snap = await _reports
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs
        .map((d) => ReportDto.fromFirestore(d.id, d.data()))
        .toList(growable: false);
  }

  @override
  Future<List<ReportDto>> getAllReports() async {
    final snap =
        await _reports.orderBy('createdAt', descending: true).get();
    return snap.docs
        .map((d) => ReportDto.fromFirestore(d.id, d.data()))
        .toList(growable: false);
  }

  @override
  Stream<List<ReportDto>> watchAllReports() {
    return _reports.orderBy('createdAt', descending: true).snapshots().map(
          (snap) => snap.docs
              .map((d) => ReportDto.fromFirestore(d.id, d.data()))
              .toList(growable: false),
        );
  }

  @override
  Future<List<ReportStatusLogDto>> getStatusLogs(String reportId) async {
    final snap = await _reports
        .doc(reportId)
        .collection('statusLogs')
        .orderBy('timestamp')
        .get();
    return snap.docs
        .map((d) => ReportStatusLogDto.fromFirestore(d.id, reportId, d.data()))
        .toList(growable: false);
  }

  @override
  Future<void> addStatusLog(ReportStatusLogDto dto) {
    return _reports
        .doc(dto.reportId)
        .collection('statusLogs')
        .add({
      'status': dto.status,
      'updatedBy': dto.updatedBy,
      'note': dto.note,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
