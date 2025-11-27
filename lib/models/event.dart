import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String name;
  final Timestamp date;
  final String location;
  final bool isActive;

  Event({
    required this.id,
    required this.name,
    required this.date,
    required this.location,
    required this.isActive,
  });

  factory Event.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Event(
      id: doc.id,
      name: data['event_name'] ?? '',
      date: data['event_date'] as Timestamp,
      location: data['location'] ?? '',
      isActive: data['is_active'] ?? false,
    );
  }

  factory Event.fromMap(Map<String, dynamic> map, String id) {
    return Event(
      id: id,
      name: map['event_name'] ?? '',
      date: map['event_date'] ?? '',
      location: '',
      isActive: true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {'event_name': name, 'event_date': date, 'location': location, 'is_active': isActive};
  }
}
