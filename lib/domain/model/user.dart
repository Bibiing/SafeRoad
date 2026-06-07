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

  /// Metode masuk: `'email'` atau `'google'`.
  final String provider;

  /// URL foto profil (mis. dari Google). `null` bila tidak ada.
  final String? photoUrl;

  /// Poin kontribusi akumulatif (Tahap 6). Default 0.
  final int contributionPoints;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.role = UserRole.user,
    this.fcmToken,
    required this.createdAt,
    this.provider = 'email',
    this.photoUrl,
    this.contributionPoints = 0,
  });

  /// Kembalikan salinan baru dengan field tertentu diganti.
  AppUser copyWith({
    String? uid,
    String? name,
    String? email,
    UserRole? role,
    String? fcmToken,
    DateTime? createdAt,
    String? provider,
    String? photoUrl,
    int? contributionPoints,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
      provider: provider ?? this.provider,
      photoUrl: photoUrl ?? this.photoUrl,
      contributionPoints: contributionPoints ?? this.contributionPoints,
    );
  }

  /// Apakah user memiliki peran admin.
  bool get isAdmin => role == UserRole.admin;

  /// Apakah user masuk lewat Google.
  bool get isGoogleProvider => provider == 'google';

  /// Label metode masuk untuk tampilan.
  String get providerLabel => isGoogleProvider ? 'Google' : 'Email';

  @override
  String toString() => 'AppUser(uid=$uid, name=$name, role=${role.name})';
}
