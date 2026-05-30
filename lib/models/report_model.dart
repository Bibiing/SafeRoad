import 'package:cloud_firestore/cloud_firestore.dart';

import 'enums.dart';

/// Model laporan kerusakan. Disimpan di koleksi `reports` (doc id auto).
class ReportModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final ReportCategory category;
  final ReportStatus status;
  final String? photoUrl;
  final double latitude;
  final double longitude;
  final String address;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ReportModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    this.status = ReportStatus.pending,
    this.photoUrl,
    required this.latitude,
    required this.longitude,
    this.address = '',
    this.createdAt,
    this.updatedAt,
  });

  factory ReportModel.fromMap(String id, Map<String, dynamic> map) {
    final created = map['createdAt'];
    final updated = map['updatedAt'];
    return ReportModel(
      id: id,
      userId: (map['userId'] ?? '') as String,
      title: (map['title'] ?? '') as String,
      description: (map['description'] ?? '') as String,
      category: ReportCategory.fromValue(map['category'] as String?),
      status: ReportStatus.fromValue(map['status'] as String?),
      photoUrl: map['photoUrl'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
      address: (map['address'] ?? '') as String,
      createdAt: created is Timestamp ? created.toDate() : null,
      updatedAt: updated is Timestamp ? updated.toDate() : null,
    );
  }

  /// Untuk menulis dokumen baru / update. Timestamp pakai server time bila null.
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'category': category.value,
      'status': status.value,
      'photoUrl': photoUrl,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  ReportModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    ReportCategory? category,
    ReportStatus? status,
    String? photoUrl,
    double? latitude,
    double? longitude,
    String? address,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReportModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      status: status ?? this.status,
      photoUrl: photoUrl ?? this.photoUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
