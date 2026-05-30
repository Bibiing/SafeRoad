import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'dto/user_dto.dart';

/// Abstraksi data source autentikasi.
///
/// DataSource hanya bertanggung jawab atas komunikasi dengan Firebase.
/// Tidak tahu tentang domain model — mengembalikan DTO.
abstract class AuthRemoteDataSource {
  /// Stream perubahan status login. Emit UID atau `null`.
  Stream<String?> authStateChanges();

  /// UID user yang sedang login.
  String? get currentUserId;

  /// Ambil data user dari Firestore.
  Future<UserDto?> fetchUser(String uid);

  /// Login dengan email & password.
  Future<UserDto> signIn({required String email, required String password});

  /// Daftar akun baru + buat profil di Firestore.
  Future<UserDto> signUp({
    required String name,
    required String email,
    required String password,
  });

  /// Logout.
  Future<void> signOut();

  /// Perbarui FCM token di profil user.
  Future<void> updateFcmToken({required String uid, required String token});
}

/// Implementasi [AuthRemoteDataSource] menggunakan Firebase Auth + Firestore.
class FirebaseAuthRemoteDataSource implements AuthRemoteDataSource {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  FirebaseAuthRemoteDataSource({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  @override
  Stream<String?> authStateChanges() =>
      _auth.authStateChanges().map((user) => user?.uid);

  @override
  String? get currentUserId => _auth.currentUser?.uid;

  @override
  Future<UserDto?> fetchUser(String uid) async {
    final doc = await _users.doc(uid).get();
    final data = doc.data();
    if (!doc.exists || data == null) return null;
    return UserDto.fromFirestore(uid, data);
  }

  @override
  Future<UserDto> signIn({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = cred.user!.uid;
    final existing = await fetchUser(uid);
    if (existing != null) return existing;

    // Buat profil fallback bila belum ada di Firestore.
    final dto = UserDto(
      uid: uid,
      name: cred.user!.displayName ?? '',
      email: cred.user!.email ?? email.trim(),
      role: 'user',
    );
    await _users.doc(uid).set(dto.toFirestore());
    return dto;
  }

  @override
  Future<UserDto> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = cred.user!.uid;
    final dto = UserDto(
      uid: uid,
      name: name.trim(),
      email: email.trim(),
      role: 'user',
    );
    await _users.doc(uid).set(dto.toFirestore());
    return dto;
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> updateFcmToken({
    required String uid,
    required String token,
  }) {
    return _users.doc(uid).update({'fcmToken': token});
  }
}
