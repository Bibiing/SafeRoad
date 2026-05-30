import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saferoad/models/user_model.dart';
import 'package:saferoad/services/auth_service.dart';
import 'package:saferoad/viewmodels/auth_viewmodel.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockAuthService authService;
  late AuthViewModel vm;

  const user = UserModel(uid: 'u1', name: 'Andi', email: 'andi@mail.com');

  setUp(() {
    authService = MockAuthService();
    vm = AuthViewModel(authService);
  });

  test('login sukses mengisi currentUser dan mematikan loading', () async {
    when(
      () => authService.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => user);

    final loadingStates = <bool>[];
    vm.addListener(() => loadingStates.add(vm.isLoading));

    final ok = await vm.login('andi@mail.com', 'rahasia');

    expect(ok, isTrue);
    expect(vm.currentUser, user);
    expect(vm.error, isNull);
    expect(vm.isLoading, isFalse);
    // Loading sempat true lalu false (notifyListeners terpanggil).
    expect(loadingStates, containsAllInOrder([true, false]));
  });

  test('login gagal mengisi error dan mengembalikan false', () async {
    when(
      () => authService.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(Exception('Email atau sandi salah'));

    final ok = await vm.login('andi@mail.com', 'salah');

    expect(ok, isFalse);
    expect(vm.error, 'Email atau sandi salah');
    expect(vm.currentUser, isNull);
    expect(vm.isLoading, isFalse);
  });

  test('register sukses mengisi currentUser', () async {
    when(
      () => authService.signUp(
        name: any(named: 'name'),
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => user);

    final ok = await vm.register('Andi', 'andi@mail.com', 'rahasia');

    expect(ok, isTrue);
    expect(vm.currentUser, user);
  });

  test('logout mengosongkan currentUser', () async {
    when(() => authService.signOut()).thenAnswer((_) async {});

    await vm.logout();

    expect(vm.currentUser, isNull);
    verify(() => authService.signOut()).called(1);
  });
}
