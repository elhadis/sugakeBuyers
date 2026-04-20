import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  Future<UserCredential> register({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }
}
