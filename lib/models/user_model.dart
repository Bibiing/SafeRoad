import 'package:cloud_firestore/cloud_firestore.dart';

import 'enums.dart';

/// Model pengguna. Disimpan di koleksi `users` dengan doc id = uid.
class UserModel {
  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final DateTime? createdAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.role = UserRole.user,
    this.createdAt,
  });

  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    final created = map['createdAt'];
    return UserModel(
      uid: uid,
      name: (map['name'] ?? '') as String,
      email: (map['email'] ?? '') as String,
      role: UserRole.fromValue(map['role'] as String?),
      createdAt: created is Timestamp ? created.toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role.value,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    UserRole? role,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isAdmin => role == UserRole.admin;
}
