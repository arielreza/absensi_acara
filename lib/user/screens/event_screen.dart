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

        final events = asyncSnapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final doc = events[index];
            final data = doc.data();

            if (data['is_active'] == true) {
              return EventCard(
                eventId: doc.id,
                title: data['event_name'],
                date: data['event_date'],
                location: data['location'],
                userId: userId,
              );
            }
            return const SizedBox.shrink();
          },
        );
      },
    );
  }
}
