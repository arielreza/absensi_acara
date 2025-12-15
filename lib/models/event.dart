// lib/models/event.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String name;
  final Timestamp date;
  final String location;
  final String organizer;
  final String description;
  final bool isActive;

  // 🔥 FIELD PENTING (QUOTA SYSTEM)
  final int participants; // quota
  final int participantsCount; // jumlah terdaftar

  // IMAGE
  final String imageUrl;
  final String imagePublicId;

  Event({
    required this.id,
    required this.name,
    required this.date,
    required this.location,
    required this.organizer,
    required this.description,
    required this.isActive,
    required this.participants,
    required this.participantsCount,
    this.imageUrl = '',
    this.imagePublicId = '',
  });

  factory Event.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Event(
      id: doc.id,
      name: data['event_name'] ?? '',
      date: data['event_date'] as Timestamp,
      location: data['location'] ?? '',
      organizer: data['organizer'] ?? '',
      description: data['description'] ?? '',
      isActive: data['is_active'] ?? false,

      // ✅ AMAN DEFAULT
      participants: data['participants'] ?? 0,
      participantsCount: data['participants_count'] ?? 0,

      imageUrl: data['image_url'] ?? '',
      imagePublicId: data['image_public_id'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'event_name': name,
      'event_date': date,
      'location': location,
      'organizer': organizer,
      'description': description,
      'is_active': isActive,
      'participants': participants,
      'participants_count': participantsCount,
      'image_url': imageUrl,
      'image_public_id': imagePublicId,
    };
  }

  // 🔥 HELPER
  bool get isFull => participantsCount >= participants;
}
