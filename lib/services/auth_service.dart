import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  /// Ambil role user dari Firestore
  Future<String?> getUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data()?['role'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Ambil seluruh data user: name, nim, email, role
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return null;

      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      return null;
    }
  }

  /// LOGIN
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
          throw 'Email tidak terdaftar';
        } else if (e.code == 'wrong-password') {
          throw 'Password salah';
        }
      }
      throw 'Gagal login: ${e.toString()}';
    }
  }

  /// LOGOUT
  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }

  /// REGISTER (+ simpan name & nim)
  Future<UserCredential?> registerUser({
    required String name,
    required String nim,
    required String email,
    required String password,
  }) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        await _firestore.collection("users").doc(result.user!.uid).set({
          "name": name,
          "nim": nim,
          "email": email,
          "role": "user",
          "createdAt": FieldValue.serverTimestamp(),
        });
      }

      notifyListeners();
      return result;

    } catch (e) {
      if (e is FirebaseAuthException) {
        if (e.code == "email-already-in-use") {
          throw "Email sudah digunakan";
        } else if (e.code == "invalid-email") {
          throw "Email tidak valid";
        } else if (e.code == "weak-password") {
          throw "Password terlalu lemah";
        }
      }
      throw "Gagal registrasi: ${e.toString()}";
    }
  }
}
