import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/model/enums.dart';
import '../../../domain/model/user.dart';

/// Data Transfer Object untuk koleksi `users` di Firestore.
///
/// Bertanggung jawab atas serialisasi/deserialisasi.
/// ViewModel tidak boleh mengakses class ini secara langsung.
class UserDto {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String? fcmToken;
  final Timestamp? createdAt;

  const UserDto({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.fcmToken,
    this.createdAt,
  });

  /// Parse dari dokumen Firestore.
  factory UserDto.fromFirestore(String uid, Map<String, dynamic> data) {
    return UserDto(
      uid: uid,
      name: (data['name'] ?? '') as String,
      email: (data['email'] ?? '') as String,
      role: (data['role'] ?? 'user') as String,
      fcmToken: data['fcmToken'] as String?,
      createdAt: data['createdAt'] as Timestamp?,
    );
  }

  /// Konversi ke Map untuk disimpan ke Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'role': role,
      if (fcmToken != null) 'fcmToken': fcmToken,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  /// Konversi DTO → domain model [AppUser].
  AppUser toDomain() {
    return AppUser(
      uid: uid,
      name: name,
      email: email,
      role: UserRole.fromFirestore(role),
      fcmToken: fcmToken,
      createdAt: createdAt?.toDate() ?? DateTime.now(),
    );
  }

  /// Konversi domain model [AppUser] → DTO.
  factory UserDto.fromDomain(AppUser user) {
    return UserDto(
      uid: user.uid,
      name: user.name,
      email: user.email,
      role: user.role.toFirestore,
      fcmToken: user.fcmToken,
      createdAt: Timestamp.fromDate(user.createdAt),
    );
  }
}
