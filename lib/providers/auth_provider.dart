import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:check_in_point/data/auth_repository.dart';
import 'package:check_in_point/models/auth_action_result.dart';

/// AuthProvider exposes authentication state and actions to the UI.
/// It listens to FirebaseAuth's authStateChanges and notifies listeners
/// when the user signs in or out.
class AuthProvider extends ChangeNotifier {
  AuthProvider({required AuthRepository authRepository})
      : _authRepository = authRepository {
    _subscription = _authRepository.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  final AuthRepository _authRepository;
  late final StreamSubscription<User?> _subscription;

  User? _user;
  User? get user => _user;
  bool get isAuthenticated => _user != null;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<AuthActionResult> signIn({required String email, required String password}) async {
    if (_isLoading) {
      return AuthActionResult.failure('Please wait, another request is in progress.');
    }
    _setLoading(true);
    _setError(null);
    try {
      await _authRepository.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return AuthActionResult.success('Signed in successfully.');
    } on FirebaseAuthException catch (e) {
      _setError(_mapFirebaseAuthError(e));
      return AuthActionResult.failure(_mapFirebaseAuthError(e));
    } catch (e) {
      _setError('Unexpected error. Please try again.');
      return AuthActionResult.failure('Unexpected error. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  Future<AuthActionResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    if (_isLoading) {
      return AuthActionResult.failure('Please wait, another request is in progress.');
    }
    _setLoading(true);
    _setError(null);
    try {
      await _authRepository.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _authRepository.updateDisplayName(name);
      return AuthActionResult.success('Account created successfully.');
    } on FirebaseAuthException catch (e) {
      _setError(_mapFirebaseAuthError(e));
      return AuthActionResult.failure(_mapFirebaseAuthError(e));
    } catch (e) {
      _setError('Unexpected error. Please try again.');
      return AuthActionResult.failure('Unexpected error. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This user has been disabled.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      default:
        return e.message ?? 'Authentication error.';
    }
  }
}


