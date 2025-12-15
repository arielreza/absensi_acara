import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StatsSection extends StatelessWidget {
  const StatsSection({super.key});

  Widget _statCard(String value, String label, Color bg, Color accent) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: accent,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('absences').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        // compute unique participant ids
        final Set<String> participantIds = {};
        final Set<String> checkedInIds = {};

        for (var d in docs) {
          final data = d.data() as Map<String, dynamic>?;
          if (data == null) continue;
          final uid = (data['user_id'] ?? '').toString();
          if (uid.isEmpty) continue;
          participantIds.add(uid);
          final status = (data['status'] ?? '').toString().toLowerCase();
          if (status == 'hadir' ||
              status == 'checked_in' ||
              status == 'present') {
            checkedInIds.add(uid);
          }
        }

        final totalParticipants = participantIds.length;
        final checkedIn = checkedInIds.length;
        final notCheckedIn = (totalParticipants - checkedIn).clamp(
          0,
          totalParticipants,
        );

        return Column(
          children: [
            Row(
              children: [
                _statCard(
                  totalParticipants.toString(),
                  'Total Participant',
                  Colors.blue.shade50,
                  Colors.indigo,
                ),
                const SizedBox(width: 12),
                _statCard(
                  checkedIn.toString(),
                  'Checked-in',
                  Colors.orange.shade50,
                  Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _statCard(
                  notCheckedIn.toString(),
                  'Not Checked-in',
                  Colors.green.shade50,
                  Colors.green,
                ),
                const SizedBox(width: 12),
                // Active events count (real-time from Firestore)
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('events')
                        .where('is_active', isEqualTo: true)
                        .snapshots(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final activeCount = snap.data?.docs.length ?? 0;

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activeCount.toString(),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Active Event',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
