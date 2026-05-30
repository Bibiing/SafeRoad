import 'enums.dart';

/// Catatan perubahan status pada sebuah laporan.
///
/// Disimpan sebagai sub-collection `statusLogs` di bawah dokumen `reports`.
/// Digunakan untuk menampilkan timeline vertikal di layar detail laporan.
class ReportStatusLog {
  final String id;
  final String reportId;
  final ReportStatus status;
  final String updatedBy;
  final String note;
  final DateTime timestamp;

  const ReportStatusLog({
    required this.id,
    required this.reportId,
    required this.status,
    required this.updatedBy,
    this.note = '',
    required this.timestamp,
  });

  @override
  String toString() =>
      'ReportStatusLog(id=$id, status=${status.name}, timestamp=$timestamp)';
}
