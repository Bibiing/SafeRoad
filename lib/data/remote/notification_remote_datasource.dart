import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/model/enums.dart';
import '../../domain/model/notification_model.dart';
import 'dto/notification_dto.dart';

/// Abstraksi data source notifikasi berbasis Firestore.
///
/// Path koleksi: `notifications/{userId}/items/{notificationId}`
abstract class NotificationRemoteDataSource {
  /// Admin: tulis notifikasi perubahan status ke Firestore user yang bersangkutan.
  Future<void> createStatusChangeNotification({
    required String userId,
    required String reportId,
    required String reportTitle,
    required ReportStatus oldStatus,
    required ReportStatus newStatus,
  });

  /// User: stream notifikasi real-time, urut terbaru di atas.
  Stream<List<AppNotification>> watchNotifications(String userId);

  /// User: tandai satu notifikasi sudah dibaca.
  Future<void> markAsRead(String userId, String notificationId);

  /// User: stream jumlah notifikasi yang belum dibaca.
  Stream<int> watchUnreadCount(String userId);

  /// User: tandai semua notifikasi sudah dibaca.
  Future<void> markAllAsRead(String userId);
}

/// Implementasi [NotificationRemoteDataSource] menggunakan Cloud Firestore.
class FirestoreNotificationRemoteDataSource
    implements NotificationRemoteDataSource {
  final FirebaseFirestore _firestore;

  FirestoreNotificationRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Referensi sub-koleksi `items` milik user tertentu.
  CollectionReference<Map<String, dynamic>> _itemsRef(String userId) =>
      _firestore.collection('notifications').doc(userId).collection('items');

  /// Teks label status yang ditampilkan di notifikasi.
  String _statusLabel(ReportStatus status) => status.label;

  @override
  Future<void> createStatusChangeNotification({
    required String userId,
    required String reportId,
    required String reportTitle,
    required ReportStatus oldStatus,
    required ReportStatus newStatus,
  }) async {
    final body =
        'Laporan "$reportTitle" telah berubah dari ${_statusLabel(oldStatus)} menjadi ${_statusLabel(newStatus)}.';

    final dto = NotificationDto(
      id: '',
      reportId: reportId,
      reportTitle: reportTitle,
      title: 'Status Laporan Diperbarui',
      body: body,
      oldStatus: oldStatus.toFirestore,
      newStatus: newStatus.toFirestore,
      isRead: false,
    );

    await _itemsRef(userId).add(dto.toFirestore());
  }

  @override
  Stream<List<AppNotification>> watchNotifications(String userId) {
    return _itemsRef(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => NotificationDto.fromFirestore(d.id, d.data()).toDomain())
              .toList(growable: false),
        );
  }

  @override
  Future<void> markAsRead(String userId, String notificationId) {
    return _itemsRef(userId).doc(notificationId).update({'isRead': true});
  }

  @override
  Stream<int> watchUnreadCount(String userId) {
    return _itemsRef(userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.size);
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    final snap =
        await _itemsRef(userId).where('isRead', isEqualTo: false).get();
    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}
