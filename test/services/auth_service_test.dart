import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saferoad/models/enums.dart';
import 'package:saferoad/services/auth_service.dart';

void main() {
  late MockFirebaseAuth auth;
  late FakeFirebaseFirestore firestore;
  late AuthService service;

  final mockUser = MockUser(uid: 'u1', email: 'andi@mail.com');

  setUp(() {
    auth = MockFirebaseAuth(mockUser: mockUser);
    firestore = FakeFirebaseFirestore();
    service = AuthService(auth: auth, firestore: firestore);
  });

  test('signUp membuat akun dan dokumen profil dengan role user', () async {
    final user = await service.signUp(
      name: 'Andi',
      email: 'andi@mail.com',
      password: 'rahasia',
    );

    expect(user.role, UserRole.user);

    final doc = await firestore.collection('users').doc(user.uid).get();
    expect(doc.exists, isTrue);
    expect(doc.data()!['name'], 'Andi');
    expect(doc.data()!['role'], UserRole.user.value);
  });

  test('signIn mengembalikan profil yang sudah ada', () async {
    await firestore.collection('users').doc('u1').set({
      'name': 'Andi Lama',
      'email': 'andi@mail.com',
      'role': 'user',
    });

    final user = await service.signIn(
      email: 'andi@mail.com',
      password: 'rahasia',
    );

    expect(user.name, 'Andi Lama');
  });

  test('signIn membuat profil fallback bila dokumen belum ada', () async {
    final user = await service.signIn(
      email: 'andi@mail.com',
      password: 'rahasia',
    );

    expect(user.uid, 'u1');
    final doc = await firestore.collection('users').doc('u1').get();
    expect(doc.exists, isTrue);
  });

  test('fetchUserModel mengembalikan null bila profil tidak ada', () async {
    final result = await service.fetchUserModel('tidak-ada');
    expect(result, isNull);
  });
}
