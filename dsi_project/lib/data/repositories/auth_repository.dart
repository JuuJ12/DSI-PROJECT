import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth;

  AuthRepository({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  User? get currentUser => _firebaseAuth.currentUser;

  // Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Realiza login com e-mail e senha
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Cria uma nova conta com e-mail e senha
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Realiza logout
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  /// Envia e-mail de redefinição de senha
  Future<void> sendPasswordResetEmail(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  /// Atualiza o displayName do usuário
  Future<void> updateDisplayName(String displayName) async {
    await _firebaseAuth.currentUser?.updateDisplayName(displayName);
    await _firebaseAuth.currentUser?.reload();
  }

  /// Verifica se há um usuário autenticado
  bool get isAuthenticated => _firebaseAuth.currentUser != null;
}
