import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event.dart';
import '../models/participant.dart';

class ParticipantListScreen extends StatelessWidget {
  final Event event;

  const ParticipantListScreen({
    super.key,
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Daftar Peserta"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Event Info Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade700),
                    const SizedBox(width: 6),
                    Text(
                      _formatDate(event.date),
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.location_on, size: 16, color: Colors.grey.shade700),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        event.location,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Participant List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('absences')
                  .where('event_id', isEqualTo: event.id)
                  .snapshots(),
              builder: (context, absenceSnapshot) {
                if (absenceSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (absenceSnapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 60, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error: ${absenceSnapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            // Refresh
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ParticipantListScreen(event: event),
                              ),
                            );
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (!absenceSnapshot.hasData || absenceSnapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada peserta terdaftar',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Ambil semua absences dan sort manual
                var absenceDocs = absenceSnapshot.data!.docs;
                
                // Sort manual berdasarkan absence_time
                absenceDocs.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  
                  // Handle null absence_time - gunakan created_at atau Timestamp.now()
                  final aTime = aData['absence_time'] as Timestamp? ?? 
                                aData['created_at'] as Timestamp? ?? 
                                Timestamp.now();
                  final bTime = bData['absence_time'] as Timestamp? ?? 
                                bData['created_at'] as Timestamp? ?? 
                                Timestamp.now();
                  
                  return aTime.compareTo(bTime); // Ascending order (paling awal di atas)
                });

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: absenceDocs.length,
                  itemBuilder: (context, index) {
                    final absenceDoc = absenceDocs[index];
                    final absenceData = absenceDoc.data() as Map<String, dynamic>;
                    final userId = absenceData['user_id'];
                    final absenceTime = absenceData['absence_time'] as Timestamp? ?? 
                                       absenceData['created_at'] as Timestamp? ?? 
                                       Timestamp.now();
                    final status = absenceData['status'] ?? 'registered';

                    // Fetch user data
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .get(),
                      builder: (context, userSnapshot) {
                        if (!userSnapshot.hasData) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  const CircularProgressIndicator(),
                                  const SizedBox(width: 16),
                                  Text('Loading user ${index + 1}...'),
                                ],
                              ),
                            ),
                          );
                        }

                        final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                        if (userData == null) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text('User not found: $userId'),
                            ),
                          );
                        }

                        final participant = Participant(
                          id: userId,
                          name: userData['name'] ?? 'Tidak ada nama',
                          nim: userData['nim'] ?? '-',
                          email: userData['email'] ?? '-',
                          eventId: event.id,
                          registrationTime: absenceTime,
                          status: status,
                        );

                        return _participantCard(context, participant, index + 1);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _participantCard(BuildContext context, Participant participant, int number) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Number Badge
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  '$number',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Participant Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    participant.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'NIM: ${participant.nim}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    participant.email,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Daftar: ${_formatDateTime(participant.registrationTime)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: _getStatusColor(participant.status),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getStatusText(participant.status),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('hadir') && !s.contains('belum')) {
      return Colors.green;
    } else if (s.contains('tidak') || s.contains('absent')) {
      return Colors.red;
    } else {
      return Colors.blue;
    }
  }

  String _getStatusText(String status) {
    final s = status.toLowerCase();
    if (s.contains('hadir') && !s.contains('belum')) {
      return 'Hadir';
    } else if (s.contains('tidak') || s.contains('absent')) {
      return 'Tidak Hadir';
    } else {
      return 'Terdaftar';
    }
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatDateTime(Timestamp timestamp) {
    final date = timestamp.toDate();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}