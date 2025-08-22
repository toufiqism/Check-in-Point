import 'package:check_in_point/data/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFirebaseAuth mockFirebaseAuth;
  late AuthRepository repository;
  late AuthStateStream authStateStream;
  late MockUser mockUser;
  late MockUserCredential mockCredential;

  setUp(() {
    registerFallbacks();
    mockFirebaseAuth = MockFirebaseAuth();
    repository = AuthRepository(firebaseAuth: mockFirebaseAuth);
    authStateStream = AuthStateStream();
    mockUser = MockUser();
    mockCredential = MockUserCredential();

    when(() => mockFirebaseAuth.authStateChanges())
        .thenAnswer((_) => authStateStream.stream);
    when(() => mockFirebaseAuth.currentUser).thenReturn(null);
  });

  tearDown(() async {
    await authStateStream.close();
  });

  group('authStateChanges', () {
    test('emits values from FirebaseAuth', () async {
      final emitted = <User?>[];
      final sub = repository.authStateChanges().listen(emitted.add);

      authStateStream.add(null);
      authStateStream.add(mockUser);
      authStateStream.add(null);

      await Future<void>.delayed(const Duration(milliseconds: 10));
      await sub.cancel();

      expect(emitted.length, 3);
      expect(emitted[0], isNull);
      expect(emitted[1], equals(mockUser));
      expect(emitted[2], isNull);
    });
  });

  group('currentUser', () {
    test('returns FirebaseAuth.currentUser', () {
      when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
      expect(repository.currentUser, equals(mockUser));
    });
  });

  group('signInWithEmailAndPassword', () {
    test('delegates to FirebaseAuth with trimmed inputs', () async {
      when(() => mockFirebaseAuth.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => mockCredential);

      final result = await repository.signInWithEmailAndPassword(
        email: '  a@b.com  ',
        password: '  pass  ',
      );

      expect(result, mockCredential);
      verify(() => mockFirebaseAuth.signInWithEmailAndPassword(
            email: 'a@b.com',
            password: '  pass  ',
          )).called(1);
    });

    test('rethrows FirebaseAuthException', () async {
      when(() => mockFirebaseAuth.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(FirebaseAuthException(code: 'wrong-password'));

      expect(
        () => repository.signInWithEmailAndPassword(
          email: 'a@b.com',
          password: 'x',
        ),
        throwsA(isA<FirebaseAuthException>()),
      );
    });
  });

  group('createUserWithEmailAndPassword', () {
    test('delegates to FirebaseAuth with trimmed inputs', () async {
      when(() => mockFirebaseAuth.createUserWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => mockCredential);

      final result = await repository.createUserWithEmailAndPassword(
        email: '  a@b.com  ',
        password: '  pass  ',
      );

      expect(result, mockCredential);
      verify(() => mockFirebaseAuth.createUserWithEmailAndPassword(
            email: 'a@b.com',
            password: '  pass  ',
          )).called(1);
    });
  });

  group('updateDisplayName', () {
    test('does nothing when currentUser is null', () async {
      when(() => mockFirebaseAuth.currentUser).thenReturn(null);
      await repository.updateDisplayName(' John ');
      // No calls to user methods should have occurred
      verifyNever(() => mockUser.updateDisplayName(any()));
      verifyNever(() => mockUser.reload());
    });

    test('updates and reloads when currentUser exists', () async {
      when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.updateDisplayName(any())).thenAnswer((_) async {});
      when(() => mockUser.reload()).thenAnswer((_) async {});

      await repository.updateDisplayName(' John ');

      verify(() => mockUser.updateDisplayName('John')).called(1);
      verify(() => mockUser.reload()).called(1);
    });
  });

  group('signOut', () {
    test('delegates to FirebaseAuth.signOut', () async {
      when(() => mockFirebaseAuth.signOut()).thenAnswer((_) async {});
      await repository.signOut();
      verify(() => mockFirebaseAuth.signOut()).called(1);
    });
  });
}


