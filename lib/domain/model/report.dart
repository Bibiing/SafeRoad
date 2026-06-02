import 'enums.dart';

/// Domain model laporan kerusakan jalan / fasilitas publik.
///
/// Pure Dart — tidak mengimpor Flutter maupun Firebase.
/// Translasi dari/ke Firestore dilakukan oleh [ReportDto].
class Report {
  final String id;
  final String userId;
  final String title;
  final String description;
  final ReportCategory category;
  final List<String> imageUrls;
  final double latitude;
  final double longitude;
  final String address;
  final ReportStatus status;
  final String? rejectionReason; // Deprecated, use adminReason
  final String? adminReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Report({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    this.imageUrls = const [],
    required this.latitude,
    required this.longitude,
    this.address = '',
    required this.status,
    this.rejectionReason,
    this.adminReason,
    required this.createdAt,
    required this.updatedAt,
  });

  Report copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    ReportCategory? category,
    List<String>? imageUrls,
    double? latitude,
    double? longitude,
    String? address,
    ReportStatus? status,
    String? rejectionReason,
    String? adminReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Report(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      imageUrls: imageUrls ?? this.imageUrls,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      adminReason: adminReason ?? this.adminReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Apakah laporan masih bisa di-edit/hapus oleh user (hanya saat pending).
  bool get isEditable => status == ReportStatus.pending;

  @override
  String toString() => 'Report(id=$id, title=$title, status=${status.name})';
}
