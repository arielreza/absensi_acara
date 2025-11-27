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

  factory User.fromMap(Map<String, dynamic> map, String id) {
    return User(
      id: id,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      nim: map['nim'] ?? '',
      role: map['role'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {'email': email, 'username': name, 'nim': nim, 'role': role};
  }
}
