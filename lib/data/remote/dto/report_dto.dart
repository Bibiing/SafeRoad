import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/model/enums.dart';
import '../../../domain/model/report.dart';

/// Data Transfer Object untuk koleksi `reports` di Firestore.
class ReportDto {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String category;
  final List<String> imageUrls;
  final double latitude;
  final double longitude;
  final String address;
  final String status;
  final String? rejectionReason;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  const ReportDto({
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
    this.createdAt,
    this.updatedAt,
  });

  /// Parse dari dokumen Firestore.
  factory ReportDto.fromFirestore(String id, Map<String, dynamic> data) {
    return ReportDto(
      id: id,
      userId: (data['userId'] ?? '') as String,
      title: (data['title'] ?? '') as String,
      description: (data['description'] ?? '') as String,
      category: (data['category'] ?? 'other') as String,
      imageUrls: List<String>.from(data['imageUrls'] ?? const []),
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0,
      address: (data['address'] ?? '') as String,
      status: (data['status'] ?? 'pending') as String,
      rejectionReason: data['rejectionReason'] as String?,
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  /// Konversi ke Map untuk disimpan ke Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'category': category,
      'imageUrls': imageUrls,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'status': status,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Map untuk update (tanpa mengubah createdAt).
  Map<String, dynamic> toUpdateMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'imageUrls': imageUrls,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'status': status,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// DTO → domain model [Report].
  Report toDomain() {
    return Report(
      id: id,
      userId: userId,
      title: title,
      description: description,
      category: ReportCategory.fromFirestore(category),
      imageUrls: imageUrls,
      latitude: latitude,
      longitude: longitude,
      address: address,
      status: ReportStatus.fromFirestore(status),
      rejectionReason: rejectionReason,
      createdAt: createdAt?.toDate() ?? DateTime.now(),
      updatedAt: updatedAt?.toDate() ?? DateTime.now(),
    );
  }

  /// Domain model [Report] → DTO.
  factory ReportDto.fromDomain(Report report) {
    return ReportDto(
      id: report.id,
      userId: report.userId,
      title: report.title,
      description: report.description,
      category: report.category.toFirestore,
      imageUrls: report.imageUrls,
      latitude: report.latitude,
      longitude: report.longitude,
      address: report.address,
      status: report.status.toFirestore,
      rejectionReason: report.rejectionReason,
      createdAt: Timestamp.fromDate(report.createdAt),
      updatedAt: Timestamp.fromDate(report.updatedAt),
    );
  }
}
