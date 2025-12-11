// lib/user/screens/event_screen.dart

import 'package:absensi_acara/models/event.dart';
import 'package:absensi_acara/services/auth_service.dart';
import 'package:absensi_acara/user/widgets/event_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EventScreen extends StatelessWidget {
  const EventScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthService>().currentUser?.uid ?? '';

    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('events').snapshots(),
      builder: (context, asyncSnapshot) {
        if (asyncSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!asyncSnapshot.hasData || asyncSnapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Tidak ada event"));
        }

        final docs = asyncSnapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final event = Event.fromFirestore(doc);
            // final imageUrl = event. as String?;

            if (event.isActive == true) {
              return EventCard(
                event: event,
                eventId: event.id,
                imageUrl: event.name,
                userId: userId,
                imageUrl: event.imageUrl, // PASS IMAGE URL
              );
            }
            return const SizedBox(height: 15);
          },
        );
      },
    );
  }
}