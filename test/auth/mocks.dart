import 'dart:async';

import 'package:check_in_point/data/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUserCredential extends Mock implements UserCredential {}

class MockUser extends Mock implements User {}

class MockAuthRepository extends Mock implements AuthRepository {}

/// Utility to create a controllable auth state stream.
class AuthStateStream {
  AuthStateStream() : controller = StreamController<User?>.broadcast();

  final StreamController<User?> controller;

  Stream<User?> get stream => controller.stream;

  void add(User? user) => controller.add(user);

  Future<void> close() async => controller.close();
}

void registerFallbacks() {
  // Strings and primitives don't need fallback values.
  // This function is kept for symmetry and future extension if needed.
}


