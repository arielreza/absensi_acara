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
  final String imageUrl;        // BARU: URL gambar dari Cloudinary
  final String imagePublicId;   // BARU: Public ID untuk referensi

  Event({
    required this.id,
    required this.name,
    required this.date,
    required this.location,
    required this.isActive,
    required this.organizer,
    required this.description,
    this.imageUrl = '',           // Default kosong jika tidak ada gambar
    this.imagePublicId = '',      // Default kosong
  });

  factory Event.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Event(
      id: doc.id,
      name: data['event_name'] ?? '',
      date: data['event_date'] as Timestamp,
      location: data['location'] ?? '',
      isActive: data['is_active'] ?? false,
      organizer: data['organizer'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['image_url'] ?? '',           // BARU
      imagePublicId: data['image_public_id'] ?? '', // BARU
    );
  }

  factory Event.fromMap(Map<String, dynamic> map, String id) {
    return Event(
      id: id,
      name: map['event_name'] ?? '',
      date: map['event_date'] ?? '',
      location: map['location'] ?? '',
      isActive: true,
      organizer: map['organizer'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['image_url'] ?? '',           // BARU
      imagePublicId: map['image_public_id'] ?? '', // BARU
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'event_name': name,
      'event_date': date,
      'location': location,
      'is_active': isActive,
      'organizer': organizer,
      'description': description,
      'image_url': imageUrl,           // BARU
      'image_public_id': imagePublicId, // BARU
    };
  }
}