import 'dart:async';

import 'package:check_in_point/models/auth_action_result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:check_in_point/providers/auth_provider.dart';
import 'package:check_in_point/data/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;

import 'mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthRepository mockRepository;
  late AuthProvider provider;
  late AuthStateStream authStateStream;
  late MockUser user;

  setUp(() {
    registerFallbacks();
    mockRepository = MockAuthRepository();
    authStateStream = AuthStateStream();
    user = MockUser();

    when(() => mockRepository.authStateChanges())
        .thenAnswer((_) => authStateStream.stream);

    provider = AuthProvider(authRepository: mockRepository);
  });

  tearDown(() async {
    await authStateStream.close();
    provider.dispose();
  });

  group('initial state', () {
    test('is unauthenticated and not loading', () {
      expect(provider.user, isNull);
      expect(provider.isAuthenticated, isFalse);
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
    });
  });

  group('auth state updates', () {
    test('updates when stream emits', () async {
      final changes = <bool>[];
      void listener() {
        changes.add(provider.isAuthenticated);
      }
      provider.addListener(listener);

      authStateStream.add(null);
      authStateStream.add(user);
      authStateStream.add(null);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(changes.contains(true), isTrue);
      expect(changes.contains(false), isTrue);

      provider.removeListener(listener);
    });
  });

  group('signIn', () {
    test('success path sets loading flags and returns success', () async {
      when(() => mockRepository.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => MockUserCredential());

      final future = provider.signIn(email: 'a@b.com', password: 'x');
      expect(provider.isLoading, isTrue);

      final result = await future;
      expect(provider.isLoading, isFalse);
      expect(result.success, isTrue);
      expect(result.message, 'Signed in successfully.');
      expect(provider.errorMessage, isNull);
    });

    test('blocks when already loading', () async {
      when(() => mockRepository.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => MockUserCredential());

      // Start first
      final first = provider.signIn(email: 'a@b.com', password: 'x');

      // Second should be blocked immediately
      final second = await provider.signIn(email: 'a@b.com', password: 'x');
      expect(second.success, isFalse);
      expect(second.message, contains('another request is in progress'));

      await first; // finish
    });

    test('maps FirebaseAuthException to user-friendly message', () async {
      when(() => mockRepository.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(FirebaseAuthException(code: 'wrong-password'));

      final result = await provider.signIn(email: 'a@b.com', password: 'x');
      expect(result, isA<AuthActionResult>());
      expect(result.success, isFalse);
      expect(result.message, 'Incorrect password.');
      expect(provider.errorMessage, 'Incorrect password.');
      expect(provider.isLoading, isFalse);
    });

    test('handles unexpected exception', () async {
      when(() => mockRepository.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(Exception('oops'));

      final result = await provider.signIn(email: 'a@b.com', password: 'x');
      expect(result.success, isFalse);
      expect(result.message, 'Unexpected error. Please try again.');
      expect(provider.errorMessage, 'Unexpected error. Please try again.');
      expect(provider.isLoading, isFalse);
    });
  });

  group('register', () {
    test('success path calls create and update name', () async {
      when(() => mockRepository.createUserWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => MockUserCredential());
      when(() => mockRepository.updateDisplayName(any()))
          .thenAnswer((_) async {});

      final result = await provider.register(
        name: 'John',
        email: 'a@b.com',
        password: 'x',
      );

      expect(result.success, isTrue);
      expect(result.message, 'Account created successfully.');
      verify(() => mockRepository.updateDisplayName('John')).called(1);
      expect(provider.errorMessage, isNull);
      expect(provider.isLoading, isFalse);
    });

    test('maps FirebaseAuthException on failure', () async {
      when(() => mockRepository.createUserWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(FirebaseAuthException(code: 'invalid-email'));

      final result = await provider.register(
        name: 'John',
        email: 'bad',
        password: 'x',
      );

      expect(result.success, isFalse);
      expect(result.message, 'Invalid email address.');
      expect(provider.errorMessage, 'Invalid email address.');
      expect(provider.isLoading, isFalse);
    });

    test('handles unexpected exception', () async {
      when(() => mockRepository.createUserWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(Exception('oops'));

      final result = await provider.register(
        name: 'John',
        email: 'a@b.com',
        password: 'x',
      );

      expect(result.success, isFalse);
      expect(result.message, 'Unexpected error. Please try again.');
      expect(provider.errorMessage, 'Unexpected error. Please try again.');
      expect(provider.isLoading, isFalse);
    });
  });

  group('signOut', () {
    test('delegates to repository', () async {
      when(() => mockRepository.signOut()).thenAnswer((_) async {});
      await provider.signOut();
      verify(() => mockRepository.signOut()).called(1);
    });
  });
}


