import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:saferoad/services/auth_service.dart';
import 'package:saferoad/viewmodels/auth_viewmodel.dart';
import 'package:saferoad/views/auth/login_view.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockAuthService authService;

  setUp(() => authService = MockAuthService());

  Widget harness() {
    return ChangeNotifierProvider<AuthViewModel>(
      create: (_) => AuthViewModel(authService),
      child: const MaterialApp(home: LoginView()),
    );
  }

  testWidgets('menolak submit saat input kosong', (tester) async {
    await tester.pumpWidget(harness());

    await tester.tap(find.widgetWithText(ElevatedButton, 'Masuk'));
    await tester.pump();

    expect(find.text('Wajib diisi'), findsNWidgets(2));
    verifyNever(
      () => authService.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
  });

  testWidgets('menampilkan pesan error saat login gagal', (tester) async {
    when(
      () => authService.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(Exception('Email atau sandi salah'));

    await tester.pumpWidget(harness());

    await tester.enterText(find.byType(TextFormField).at(0), 'andi@mail.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'rahasia');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Masuk'));
    await tester.pumpAndSettle();

    expect(find.text('Email atau sandi salah'), findsOneWidget);
  });
}
