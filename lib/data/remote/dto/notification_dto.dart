import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/model/notification_model.dart';

/// DTO untuk koleksi `notifications/{userId}/items/{id}` di Firestore.
class NotificationDto {
  final String id;
  final String reportId;
  final String reportTitle;
  final String title;
  final String body;
  final String oldStatus;
  final String newStatus;
  final bool isRead;
  final Timestamp? createdAt;

  const NotificationDto({
    required this.id,
    required this.reportId,
    required this.reportTitle,
    required this.title,
    required this.body,
    required this.oldStatus,
    required this.newStatus,
    required this.isRead,
    this.createdAt,
  });

  /// Parse dari dokumen Firestore.
  factory NotificationDto.fromFirestore(String id, Map<String, dynamic> data) {
    return NotificationDto(
      id: id,
      reportId: (data['reportId'] ?? '') as String,
      reportTitle: (data['reportTitle'] ?? '') as String,
      title: (data['title'] ?? '') as String,
      body: (data['body'] ?? '') as String,
      oldStatus: (data['oldStatus'] ?? '') as String,
      newStatus: (data['newStatus'] ?? '') as String,
      isRead: (data['isRead'] ?? false) as bool,
      createdAt: data['createdAt'] as Timestamp?,
    );
  }

  /// Konversi ke Map untuk disimpan ke Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'reportId': reportId,
      'reportTitle': reportTitle,
      'title': title,
      'body': body,
      'oldStatus': oldStatus,
      'newStatus': newStatus,
      'isRead': isRead,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  /// DTO → domain model [AppNotification].
  AppNotification toDomain() {
    return AppNotification(
      id: id,
      reportId: reportId,
      reportTitle: reportTitle,
      title: title,
      body: body,
      oldStatus: oldStatus,
      newStatus: newStatus,
      isRead: isRead,
      createdAt: createdAt?.toDate() ?? DateTime.now(),
    );
  }
}
