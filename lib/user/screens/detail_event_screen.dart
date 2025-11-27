import 'package:absensi_acara/models/event.dart';
import 'package:absensi_acara/user/service/event_register_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DetailEventScreen extends ConsumerWidget {
  final String eventId;
  final String userId;

  const DetailEventScreen({super.key, required this.eventId, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('absences')
          .where('user_id', isEqualTo: userId)
          .where('event_id', isEqualTo: eventId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text("Loading...");
        }

        String status = "Daftar";

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final doc = snapshot.data!.docs.first;

          final userStatus = (doc['status'] ?? '').toString().toLowerCase();

          if (userStatus == "belum hadir") {
            status = "Sudah Daftar";
          } else if (userStatus == "hadir") {
            status = "Hadir";
          }
        }

        final Color statusColor = (status == "Daftar") ? Colors.green : Colors.grey;

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
            return Scaffold(
              backgroundColor: Colors.white,
              body: ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final event = Event.fromFirestore(doc);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          Image.asset(
                            'assets/header.png',
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            top: 40,
                            left: 16,
                            child: Icon(Icons.arrow_back, color: Colors.black),
                          ),
                          Positioned(
                            top: 40,
                            right: 60,
                            child: Icon(Icons.share, color: Colors.black),
                          ),
                          Positioned(
                            top: 40,
                            right: 16,
                            child: Icon(Icons.favorite_border, color: Colors.black),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.name,
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text(event.location, style: TextStyle(color: Colors.blue)),
                                Text('• '),
                                Text('Kec. Klojen', style: TextStyle(color: Colors.blue)),
                              ],
                            ),
                            const SizedBox(height: 12),

                            Row(
                              children: [
                                CircleAvatar(radius: 14, backgroundColor: Colors.black12),
                                const SizedBox(width: 8),
                                Text(event.organizer),
                                const SizedBox(width: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.black26),
                                  ),
                                  child: Text('Follow'),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),
                            Text(
                              'Overview',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(event.description),
                            const SizedBox(height: 4),
                            Text('Readmore >', style: TextStyle(color: Colors.blue)),

                            const SizedBox(height: 24),
                            Text(
                              'Good to Know',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),

                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 6,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Highlights', style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today, size: 20),
                                      SizedBox(width: 8),
                                      Text('Next date 22/11'),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Icon(Icons.access_time, size: 20),
                                      SizedBox(width: 8),
                                      Text('2 Hours'),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on, size: 20),
                                      SizedBox(width: 8),
                                      Text('Auditorium Lantai 8 Jurusan Teknologi Informasi'),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Free',
                                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                    ),
                                    Text('Multiple dates'),
                                  ],
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.purple,
                                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () async {
                                    ref
                                        .read(eventRegisterService)
                                        .daftarEvent(eventId: eventId, userId: userId);
                                  },
                                  child: Text(
                                    'Check availability',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
