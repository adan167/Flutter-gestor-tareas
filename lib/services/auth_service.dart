import 'package:firebase_auth/firebase_auth.dart';

/// Encapsula toda la lógica de autenticación con Firebase Auth.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Stream que avisa cuando el usuario inicia o cierra sesión.
  Stream<User?> get authChanges => _auth.authStateChanges();

  /// Usuario actual (null si no hay sesión).
  User? get currentUser => _auth.currentUser;

  /// Crea una cuenta nueva con correo y contraseña.
  Future<void> register(String email, String password) async {
    await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Inicia sesión con correo y contraseña.
  Future<void> login(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Cierra la sesión.
  Future<void> logout() => _auth.signOut();
}
