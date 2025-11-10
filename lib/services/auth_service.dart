import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? get currentUser => _auth.currentUser;
  
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      notifyListeners();
      return result;
    } catch (e) {
      if (e is FirebaseAuthException) {
        if (e.code == 'user-not-found') {
          throw 'Email tidak terdaftar sebagai operator';
        } else if (e.code == 'wrong-password') {
          throw 'Password salah';
        }
      }
      throw 'Gagal login: ${e.toString()}';
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }
}