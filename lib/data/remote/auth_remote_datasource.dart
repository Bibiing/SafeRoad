import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/constants/app_constants.dart';
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

  /// Masuk dengan Google. Kembalikan `null` bila dibatalkan user.
  Future<UserDto?> signInWithGoogle();

  /// Logout.
  Future<void> signOut();

  /// Perbarui FCM token di profil user.
  Future<void> updateFcmToken({required String uid, required String token});

  /// Tambah poin kontribusi (akumulatif) ke dokumen user.
  Future<void> incrementPoints(String uid, int delta);
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
      provider: 'email',
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
      provider: 'email',
    );
    await _users.doc(uid).set(dto.toFirestore());
    return dto;
  }

  // ── Google Sign-In (google_sign_in v7) ──────────────────────────────
  bool _googleInitialized = false;

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    const serverClientId = AppConstants.googleServerClientId;
    await GoogleSignIn.instance.initialize(
      serverClientId: serverClientId.isEmpty ? null : serverClientId,
    );
    _googleInitialized = true;
  }

  @override
  Future<UserDto?> signInWithGoogle() async {
    await _ensureGoogleInitialized();

    final GoogleSignInAccount account;
    try {
      account = await GoogleSignIn.instance.authenticate(
        scopeHint: const ['email', 'profile'],
      );
    } on GoogleSignInException catch (e) {
      // User menutup dialog → bukan error, kembalikan null.
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }

    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw Exception(
        'Gagal memperoleh token Google. Pastikan konfigurasi OAuth '
        '(serverClientId / GoogleService-Info.plist) sudah benar.',
      );
    }

    final credential = GoogleAuthProvider.credential(idToken: idToken);
    final cred = await _auth.signInWithCredential(credential);
    final user = cred.user!;
    final uid = user.uid;

    // Pertahankan profil lama (termasuk poin) bila sudah ada. Namun segarkan
    // photoUrl bila Google mengirim foto baru/berubah, agar foto profil tetap
    // sinkron (termasuk untuk akun lama yang dibuat sebelum field ini ada).
    final existing = await fetchUser(uid);
    if (existing != null) {
      final freshPhoto = user.photoURL;
      if (freshPhoto != null &&
          freshPhoto.isNotEmpty &&
          freshPhoto != existing.photoUrl) {
        await _users.doc(uid).update({'photoUrl': freshPhoto});
        return UserDto(
          uid: existing.uid,
          name: existing.name,
          email: existing.email,
          role: existing.role,
          fcmToken: existing.fcmToken,
          createdAt: existing.createdAt,
          provider: existing.provider,
          photoUrl: freshPhoto,
          contributionPoints: existing.contributionPoints,
        );
      }
      return existing;
    }

    final dto = UserDto(
      uid: uid,
      name: user.displayName ?? account.displayName ?? '',
      email: user.email ?? account.email,
      role: 'user',
      provider: 'google',
      photoUrl: user.photoURL,
    );
    await _users.doc(uid).set(dto.toFirestore());
    return dto;
  }

  @override
  Future<void> signOut() async {
    // Putuskan sesi Google agar akun bisa diganti saat login berikutnya.
    try {
      await _ensureGoogleInitialized();
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Abaikan: user mungkin tidak masuk lewat Google.
    }
    await _auth.signOut();
  }

  @override
  Future<void> updateFcmToken({
    required String uid,
    required String token,
  }) {
    return _users.doc(uid).update({'fcmToken': token});
  }

  @override
  Future<void> incrementPoints(String uid, int delta) {
    return _users.doc(uid).update({
      'contributionPoints': FieldValue.increment(delta),
    });
  }
}
