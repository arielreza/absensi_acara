import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event.dart';
import 'participant_list_screen.dart';

class ParticipantManagementScreen extends StatelessWidget {
  const ParticipantManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Participant Management"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('events')
            .orderBy('event_date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('Belum ada event'),
            );
          }

          final events = snapshot.data!.docs
              .map((doc) => Event.fromFirestore(doc))
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return _eventCard(context, event);
            },
          );
        },
      ),
    );
  }

  Widget _eventCard(BuildContext context, Event event) {
    // Hitung jumlah peserta dari collection absences
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('absences')
          .where('event_id', isEqualTo: event.id)
          .snapshots(),
      builder: (context, absenceSnapshot) {
        int participantCount = 0;
        if (absenceSnapshot.hasData) {
          participantCount = absenceSnapshot.data!.docs.length;
        }

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: InkWell(
            onTap: () {
              // Navigate ke list peserta
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ParticipantListScreen(event: event),
                ),
              );
            },
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event Image (jika ada)
                  if (event.imageUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        event.imageUrl,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 150,
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.image, size: 50),
                          );
                        },
                      ),
                    ),
                  
                  if (event.imageUrl.isNotEmpty) const SizedBox(height: 12),

                  // Event Name
                  Text(
                    event.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Event Date
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(event.date),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Location
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          event.location,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Participant Count & Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.people,
                              size: 16,
                              color: Colors.deepPurple,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$participantCount Peserta',
                              style: const TextStyle(
                                color: Colors.deepPurple,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: event.isActive
                              ? Colors.green.shade50
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          event.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            color: event.isActive
                                ? Colors.green.shade700
                                : Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}