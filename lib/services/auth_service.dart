import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  User? get currentUser => _auth.currentUser;
  
  /// Get user role from Firestore ('admin' or 'user')
  Future<String?> getUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data()?['role'] as String?;
    } catch (_) {
      return null;
    }
  }
  
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

  /// Register a new public user with email & password
  Future<UserCredential?> registerWithEmail(String email, String password) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Save user as 'user' role in Firestore
      if (result.user != null) {
        await _firestore.collection('users').doc(result.user!.uid).set({
          'email': email,
          'role': 'user',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      
      notifyListeners();
      return result;
    } catch (e) {
      if (e is FirebaseAuthException) {
        if (e.code == 'email-already-in-use') {
          throw 'Email sudah terdaftar';
        } else if (e.code == 'invalid-email') {
          throw 'Email tidak valid';
        } else if (e.code == 'weak-password') {
          throw 'Password terlalu lemah (minimal 6 karakter)';
        }
      }
      throw 'Gagal mendaftar: ${e.toString()}';
    }
  }
}