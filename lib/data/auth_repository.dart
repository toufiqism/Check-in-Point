import 'package:firebase_auth/firebase_auth.dart';

/// AuthRepository encapsulates all FirebaseAuth interactions.
/// This abstraction helps keep UI and state management layers decoupled
/// from the underlying authentication SDK, supporting SOLID principles.
class AuthRepository {
  AuthRepository({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;

  Stream<User?> authStateChanges() => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> updateDisplayName(String displayName) async {
    final User? user = _firebaseAuth.currentUser;
    if (user != null) {
      await user.updateDisplayName(displayName.trim());
      await user.reload();
    }
  }

  Future<void> signOut() => _firebaseAuth.signOut();
}


