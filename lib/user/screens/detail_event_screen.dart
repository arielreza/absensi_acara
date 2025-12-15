import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:absensi_acara/models/event.dart';
import 'package:absensi_acara/user/service/event_register_service.dart';
import 'package:absensi_acara/user/screens/success_screen.dart';
import 'review_ticket_screen.dart';

class DetailEventScreen extends ConsumerWidget {
  final String eventId;
  final String userId;

  const DetailEventScreen({
    super.key,
    required this.eventId,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('absences')
          .where('event_id', isEqualTo: eventId)
          .where('user_id', isEqualTo: userId)
          .snapshots(),
      builder: (context, absSnapshot) {
        bool isRegistered = false;
        bool isHadir = false;
        String? absenceId;

        if (absSnapshot.hasData && absSnapshot.data!.docs.isNotEmpty) {
          final doc = absSnapshot.data!.docs.first;
          absenceId = doc.id;
          isRegistered = true;
          isHadir = doc['status'] == 'hadir';
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('events')
              .doc(eventId)
              .snapshots(),
          builder: (context, eventSnapshot) {
            if (!eventSnapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final event = Event.fromFirestore(eventSnapshot.data!);

            return Scaffold(
              backgroundColor: Colors.white,
              body: Stack(
                children: [
                  SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// HEADER IMAGE
                        SizedBox(
                          height: 300,
                          width: double.infinity,
                          child: event.imageUrl.isNotEmpty
                              ? Image.network(event.imageUrl, fit: BoxFit.cover)
                              : Container(color: Colors.grey[300]),
                        ),

                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "${event.location} • Kec. Klojen",
                                style: const TextStyle(
                                  color: Colors.deepPurple,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "Multiple dates",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),

                        /// ORGANIZER
                        ListTile(
                          leading: CircleAvatar(
                            child: Text(event.organizer[0].toUpperCase()),
                          ),
                          title: Text("By ${event.organizer}"),
                          subtitle: const Text("1227 followers"),
                          trailing: OutlinedButton(
                            onPressed: () {},
                            child: const Text("Follow"),
                          ),
                        ),

                        /// OVERVIEW
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Overview",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(event.description),
                              const SizedBox(height: 8),
                              const Text(
                                "Read more",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),

                        /// GOOD TO KNOW
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x15000000),
                                  blurRadius: 8,
                                ),
                              ],
                              color: Colors.white,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Highlights",
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 12),
                                const Row(
                                  children: [
                                    Icon(Icons.calendar_today, size: 14),
                                    SizedBox(width: 8),
                                    Text("1 January 2025"),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Row(
                                  children: [
                                    Icon(Icons.access_time, size: 14),
                                    SizedBox(width: 8),
                                    Text("2 hours"),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 14),
                                    const SizedBox(width: 8),
                                    Text(event.location),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 120),
                      ],
                    ),
                  ),

                  // Back button (top-left)
                  Positioned(
                    top: 32,
                    left: 12,
                    child: CircleAvatar(
                      backgroundColor: Colors.white.withOpacity(0.9),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.black87,
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ),

                  /// BOTTOM BAR
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(color: Color(0x22000000), blurRadius: 10),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Free",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              Text("Multiple dates"),
                            ],
                          ),

                          /// BUTTON
                          ElevatedButton(
                            onPressed: isHadir
                                ? null
                                : () async {
                                    try {
                                      if (!isRegistered) {
                                        // Navigate first to review ticket page; registration happens there when user taps Continue
                                        if (context.mounted) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  ReviewTicketScreen(
                                                    eventId: eventId,
                                                    userId: userId,
                                                  ),
                                            ),
                                          );
                                        }
                                      } else {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (c) => AlertDialog(
                                            title: const Text(
                                              'Batalkan Pendaftaran',
                                            ),
                                            content: const Text(
                                              'Anda yakin ingin membatalkan pendaftaran untuk event ini?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.of(c).pop(false),
                                                child: const Text('BATAL'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () =>
                                                    Navigator.of(c).pop(true),
                                                child: const Text('YA'),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirm != true) return;

                                        await ref
                                            .read(eventRegisterService)
                                            .unregisterEvent(
                                              eventId: eventId,
                                              userId: userId,
                                              absenceId: absenceId!,
                                            );

                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Pendaftaran dibatalkan',
                                              ),
                                            ),
                                          );
                                          Navigator.of(context).pop();
                                        }
                                      }
                                    } catch (e) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text('Gagal: $e')),
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: !isRegistered
                                  ? const Color(0xFF594AFC)
                                  : Colors.redAccent,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Text(
                              !isRegistered ? "Daftar" : "Batalkan",
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
