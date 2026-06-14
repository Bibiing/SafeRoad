import '../../domain/model/user.dart';
import '../../domain/repository/auth_repository.dart';
import '../remote/auth_remote_datasource.dart';

/// Implementasi konkret [AuthRepository].
///
/// Menerjemahkan antara DTO dari [AuthRemoteDataSource] dan domain model
/// [AppUser] yang digunakan oleh ViewModel.
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _dataSource;

  AuthRepositoryImpl(this._dataSource);

  @override
  Stream<String?> authStateChanges() => _dataSource.authStateChanges();

  @override
  String? get currentUserId => _dataSource.currentUserId;

  @override
  Future<AppUser?> fetchUser(String uid) async {
    final dto = await _dataSource.fetchUser(uid);
    return dto?.toDomain();
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final dto = await _dataSource.signIn(email: email, password: password);
    return dto.toDomain();
  }

  @override
  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final dto = await _dataSource.signUp(
      name: name,
      email: email,
      password: password,
    );
    return dto.toDomain();
  }

  @override
  Future<AppUser?> signInWithGoogle() async {
    final dto = await _dataSource.signInWithGoogle();
    return dto?.toDomain();
  }

  @override
  Future<void> signOut() => _dataSource.signOut();

  @override
  Future<void> updateFcmToken({
    required String uid,
    required String token,
  }) {
    return _dataSource.updateFcmToken(uid: uid, token: token);
  }

  @override
  Future<void> incrementPoints(String uid, int delta) {
    return _dataSource.incrementPoints(uid, delta);
  }

  @override
  Future<List<AppUser>> getTopContributors(int limit) async {
    final dtos = await _dataSource.getTopContributors(limit);
    return dtos.map((dto) => dto.toDomain()).toList();
  }
}
