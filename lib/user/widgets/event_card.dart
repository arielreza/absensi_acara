import 'package:absensi_acara/user/service/event_register_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class EventCard extends ConsumerWidget {
  final String eventId;
  final String title;
  final Timestamp date;
  final String location;
  final String userId;

  const EventCard({
    super.key,
    required this.eventId,
    required this.title,
    required this.date,
    required this.location,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventDate = date.toDate();
    final dateFormatted = DateFormat("EEE, dd MMM yyyy").format(eventDate);
    final timeFormatted = DateFormat("HH:mm").format(eventDate);

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

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------------------- IMAGE ----------------------
              SizedBox(height: 160),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          "$dateFormatted   •   $timeFormatted",
                          style: const TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: Colors.grey),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            location,
                            style: const TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ---------------------- BUTTON ----------------------
                    InkWell(
                      onTap: () async {
                        ref
                            .read(eventRegisterService)
                            .daftarEvent(eventId: eventId, userId: userId);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
