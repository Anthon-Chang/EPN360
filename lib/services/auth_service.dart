import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late final Stream<User?> authStateChanges = _auth.authStateChanges();

  /// Usuario actualmente autenticado, si existe.
  User? get currentUser => _auth.currentUser;

  /// Inicia sesión con correo y contraseña.
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapAuthError(e.code);
    } catch (e) {
      debugPrint('Error inesperado en signIn: $e');
      return 'Ocurrió un error inesperado. Intenta de nuevo.';
    }
  }

  Future<RegisterResult> register({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return RegisterResult(uid: credential.user?.uid);
    } on FirebaseAuthException catch (e) {
      return RegisterResult(error: _mapAuthError(e.code));
    } catch (e) {
      debugPrint('Error inesperado en register: $e');
      return RegisterResult(
        error: 'Ocurrió un error inesperado. Intenta de nuevo.',
      );
    }
  }

  /// Envía un correo de recuperación de contraseña.
  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapAuthError(e.code);
    }
  }

  /// Cierra la sesión actual.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No existe una cuenta con ese correo.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos.';
      case 'invalid-email':
        return 'El correo ingresado no es válido.';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con ese correo.';
      case 'weak-password':
        return 'La contraseña es demasiado débil (mínimo 6 caracteres).';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde.';
      default:
        return 'Error de autenticación: $code';
    }
  }
}

class RegisterResult {
  RegisterResult({this.uid, this.error});

  final String? uid;
  final String? error;

  bool get isSuccess => error == null && uid != null;
}
