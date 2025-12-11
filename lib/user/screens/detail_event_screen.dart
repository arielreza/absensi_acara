// lib/user/screens/detail_event_screen.dart

import 'package:absensi_acara/models/event.dart';
import 'package:absensi_acara/user/screens/success_screen.dart';
import 'package:absensi_acara/user/service/event_register_service.dart';
import 'package:absensi_acara/user/widgets/placeholder_image.dart';
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
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
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

        final Color statusColor = (status == "Daftar") ? const Color(0xFF594AFC) : Colors.grey;
        final parentContext = context;

        return StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('events')
              .where(FieldPath.documentId, isEqualTo: eventId)
              .snapshots(),
          builder: (context, asyncSnapshot) {
            if (asyncSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            if (!asyncSnapshot.hasData || asyncSnapshot.data!.docs.isEmpty) {
              return const Scaffold(body: Center(child: Text("Event tidak ditemukan")));
            }

            final doc = asyncSnapshot.data!.docs.first;
            final event = Event.fromFirestore(doc);

            return Scaffold(
              backgroundColor: const Color(0xFFFAFAFA),
              body: Stack(
                children: [
                  // Main Content
                  SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ===================== HEADER IMAGE =====================
                        Stack(
                          children: [
                            // Event Image dari Cloudinary atau Placeholder
                            Container(
                              width: double.infinity,
                              height: 300,
                              decoration: const BoxDecoration(color: Color(0xFFD9D9D9)),
                              child: event.imageUrl.isNotEmpty
                                  ? Image.network(
                                      event.imageUrl,
                                      width: double.infinity,
                                      height: 300,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Container(
                                          color: const Color(0xFFD9D9D9),
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              color: Color(0xFF594AFC),
                                            ),
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        return PlaceholderImage();
                                      },
                                    )
                                  : PlaceholderImage(),
                            ),

                            // Gradient Overlay untuk readability
                            Container(
                              width: double.infinity,
                              height: 300,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.3),
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.5),
                                  ],
                                ),
                              ),
                            ),

                            // Top Icons
                            Positioned(
                              top: 50,
                              left: 16,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 50,
                              right: 60,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.share, color: Colors.black),
                                  onPressed: () {},
                                ),
                              ),
                            ),
                            Positioned(
                              top: 50,
                              right: 8,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.favorite_border, color: Colors.black),
                                  onPressed: () {},
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Event Title and Location
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                  height: 1.3,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    event.location,
                                    style: const TextStyle(
                                      color: Color(0xFF594AFC),
                                      fontSize: 14,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  Container(
                                    width: 5,
                                    height: 5,
                                    margin: const EdgeInsets.symmetric(horizontal: 8),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF594AFC),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const Text(
                                    'Kec. Klojen',
                                    style: TextStyle(
                                      color: Color(0xFF594AFC),
                                      fontSize: 14,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Multiple dates',
                                style: TextStyle(
                                  color: Color(0xFF777777),
                                  fontSize: 14,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Organizer Section
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(color: Color(0x33CACACA)),
                              bottom: BorderSide(color: Color(0x33CACACA)),
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 25,
                                backgroundColor: const Color(0xFFD9D9D9),
                                child: Text(
                                  event.organizer[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text.rich(
                                      TextSpan(
                                        children: [
                                          const TextSpan(
                                            text: 'By ',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.black,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                          TextSpan(
                                            text: event.organizer,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      '1227 followers',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF777777),
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.black),
                                ),
                                child: const Text(
                                  'Follow',
                                  style: TextStyle(fontSize: 12, fontFamily: 'Poppins'),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Overview Section
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: Color(0x33CACACA))),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Overview',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                event.description,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black,
                                  height: 1.5,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Row(
                                children: [
                                  Text(
                                    'Read more',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF777777),
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(
                                    Icons.keyboard_arrow_down,
                                    size: 16,
                                    color: Color(0xFF777777),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Good to Know Section
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Good to Know',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x19000000),
                                      blurRadius: 6,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Highlights',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                    const SizedBox(height: 15),
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today, size: 14),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Next date ${event.date}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    const Row(
                                      children: [
                                        Icon(Icons.access_time, size: 14),
                                        SizedBox(width: 8),
                                        Text(
                                          '2 hours',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.black,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.location_on, size: 14),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            event.location,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.black,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),

                  // Bottom Button
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x19000000),
                            blurRadius: 15,
                            offset: Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Free',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              Text(
                                'Multiple dates',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                          ElevatedButton(
                            onPressed: status == "Daftar"
                                ? () async {
                                    await ref
                                        .read(eventRegisterService)
                                        .daftarEvent(eventId: eventId, userId: userId);

                                    Navigator.push(
                                      parentContext,
                                      MaterialPageRoute(builder: (_) => const SuccessScreen()),
                                    );
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: statusColor,
                              disabledBackgroundColor: Colors.grey,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                              elevation: 5,
                              shadowColor: const Color(0x11000000),
                            ),
                            child: Text(
                              status,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Poppins',
                              ),
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
