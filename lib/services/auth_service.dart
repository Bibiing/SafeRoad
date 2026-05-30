import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/enums.dart';
import '../models/user_model.dart';

/// Satu-satunya tempat yang menyentuh FirebaseAuth + koleksi `users`.
/// Dependency Firebase di-inject lewat konstruktor agar bisa di-mock saat test.
class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// Ambil profil dari Firestore. Null bila dokumen belum ada.
  Future<UserModel?> fetchUserModel(String uid) async {
    final doc = await _users.doc(uid).get();
    final data = doc.data();
    if (!doc.exists || data == null) return null;
    return UserModel.fromMap(uid, data);
  }

  /// Masuk lalu kembalikan profil user. Profil dibuat bila belum ada.
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = cred.user!.uid;
    final existing = await fetchUserModel(uid);
    if (existing != null) return existing;

    final fallback = UserModel(
      uid: uid,
      name: cred.user!.displayName ?? '',
      email: cred.user!.email ?? email.trim(),
    );
    await _users.doc(uid).set(fallback.toMap());
    return fallback;
  }

  /// Daftar akun baru + buat dokumen profil di koleksi `users`.
  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = cred.user!.uid;
    final user = UserModel(
      uid: uid,
      name: name.trim(),
      email: email.trim(),
      role: UserRole.user,
    );
    await _users.doc(uid).set(user.toMap());
    return user;
  }

  Future<void> signOut() => _auth.signOut();
}
