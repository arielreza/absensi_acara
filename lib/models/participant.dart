import 'package:cloud_firestore/cloud_firestore.dart';

class Participant {
  final String id; // user id
  final String name;
  final String nim;
  final String email;
  final String eventId;
  final Timestamp registrationTime; // waktu pendaftaran/absen
  final String status; // hadir, tidak hadir, dll

  Participant({
    required this.id,
    required this.name,
    required this.nim,
    required this.email,
    required this.eventId,
    required this.registrationTime,
    required this.status,
  });

  // Factory untuk membuat Participant dari Firestore
  // Biasanya data ini digabung dari collection 'users' dan 'absences'
  factory Participant.fromMap(Map<String, dynamic> map, String userId) {
    return Participant(
      id: userId,
      name: map['name'] ?? '',
      nim: map['nim'] ?? '',
      email: map['email'] ?? '',
      eventId: map['event_id'] ?? '',
      registrationTime: map['registration_time'] ?? Timestamp.now(),
      status: map['status'] ?? 'registered',
    );
  }

  // Convert to Map untuk keperluan database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'nim': nim,
      'email': email,
      'event_id': eventId,
      'registration_time': registrationTime,
      'status': status,
    };
  }
}