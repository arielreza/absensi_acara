// lib/admin/widgets/upcoming_events_section.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'event_card.dart';

class UpcomingEventsSection extends StatelessWidget {
  const UpcomingEventsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Upcoming Events",
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
        ),
        const SizedBox(height: 12),
        _buildEventsList(),
      ],
    );
  }

  Widget _buildEventsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("events")
          .where("is_active", isEqualTo: true)
          .orderBy("event_date", descending: false)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final QuerySnapshot? snap = snapshot.data;
        final docs = snap?.docs ?? [];

        if (docs.isEmpty) {
          return const Text(
            "No Active Events",
            style: TextStyle(color: Colors.black54, fontFamily: 'Poppins'),
          );
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return EventCard(eventId: doc.id, data: data);
          }).toList(),
        );
      },
    );
  }
}
