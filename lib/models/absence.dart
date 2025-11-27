import 'package:cloud_firestore/cloud_firestore.dart';

class Absence {
  final String id;
  final String eventId;
  final String userId;
  final Timestamp absenceTime;
  final String status;

  Absence({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.absenceTime,
    required this.status,
  });

  factory Absence.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return Absence(
      id: doc.id,
      eventId: map['event_id'],
      userId: map['user_id'],
      absenceTime: map['absence_time'] ?? Timestamp.now(),
      status: map['status'],
    );
  }

  factory Absence.fromMap(Map<String, dynamic> map, String id) {
    return Absence(
      id: id,
      eventId: map['event_id'] ?? '',
      userId: map['user_id'] ?? '',
      absenceTime: map['absence_time'] ?? Timestamp.now(),
      status: map['status'] ?? '',
    );
  }
}
