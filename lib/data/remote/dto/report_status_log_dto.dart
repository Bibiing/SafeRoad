import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/model/enums.dart';
import '../../../domain/model/report_status_log.dart';

/// Data Transfer Object untuk sub-collection `statusLogs` di Firestore.
class ReportStatusLogDto {
  final String id;
  final String reportId;
  final String status;
  final String updatedBy;
  final String note;
  final Timestamp? timestamp;

  const ReportStatusLogDto({
    required this.id,
    required this.reportId,
    required this.status,
    required this.updatedBy,
    this.note = '',
    this.timestamp,
  });

  /// Parse dari dokumen Firestore.
  factory ReportStatusLogDto.fromFirestore(
    String id,
    String reportId,
    Map<String, dynamic> data,
  ) {
    return ReportStatusLogDto(
      id: id,
      reportId: reportId,
      status: (data['status'] ?? 'pending') as String,
      updatedBy: (data['updatedBy'] ?? '') as String,
      note: (data['note'] ?? '') as String,
      timestamp: data['timestamp'] as Timestamp?,
    );
  }

  /// DTO → domain model [ReportStatusLog].
  ReportStatusLog toDomain() {
    return ReportStatusLog(
      id: id,
      reportId: reportId,
      status: ReportStatus.fromFirestore(status),
      updatedBy: updatedBy,
      note: note,
      timestamp: timestamp?.toDate() ?? DateTime.now(),
    );
  }
}
