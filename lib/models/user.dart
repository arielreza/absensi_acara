import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String email;
  final String name;
  final String nim;
  final String role;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.nim,
    required this.role,
  });

  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return User(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      nim: data['nim'] ?? '',
      role: data['role'] ?? 'user',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {'email': email, 'username': name, 'nim': nim, 'role': role};
  }
}
