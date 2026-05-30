import 'enums.dart';

/// Domain model pengguna SafeRoad.
///
/// Pure Dart — tidak mengimpor Flutter maupun Firebase.
/// Translasi dari/ke Firestore dilakukan oleh [UserDto].
class AppUser {
  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final String? fcmToken;
  final DateTime createdAt;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.role = UserRole.user,
    this.fcmToken,
    required this.createdAt,
  });

  /// Kembalikan salinan baru dengan field tertentu diganti.
  AppUser copyWith({
    String? uid,
    String? name,
    String? email,
    UserRole? role,
    String? fcmToken,
    DateTime? createdAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Apakah user memiliki peran admin.
  bool get isAdmin => role == UserRole.admin;

  @override
  String toString() => 'AppUser(uid=$uid, name=$name, role=${role.name})';
}
