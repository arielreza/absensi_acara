import 'package:absensi_acara/models/event.dart';
import 'package:absensi_acara/user/screens/detail_event_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class EventCard extends ConsumerWidget {
  final Event event;
  final String eventId;
  final String userId;
  final String? imageUrl; 

  const EventCard({
    super.key,
    required this.event,
    required this.eventId,
    required this.userId,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Parsing Tanggal yang Aman
    DateTime eventDate = DateTime.now();
    try {
      if (event.date is Timestamp) {
        eventDate = (event.date as Timestamp).toDate();
      } else {
        eventDate = event.date as DateTime;
      }
    } catch (e) {
      // Fallback diam jika gagal
    }

    final String dateFormatted = DateFormat('EEE, MMM d').format(eventDate);
    final String timeFormatted = DateFormat('hh.mm a').format(eventDate); 

    // Menggunakan Image URL dari parameter jika ada, fallback ke event object
    final String displayImage = (imageUrl != null && imageUrl!.isNotEmpty) 
        ? imageUrl! 
        : event.imageUrl;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailEventScreen(eventId: eventId, userId: userId),
          ),
        );
      },
      child: Container(
        width: 284, 
        margin: const EdgeInsets.only(right: 20),
        padding: const EdgeInsets.all(10), // Padding dalam container putih
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x19000000), 
              blurRadius: 6,
              offset: Offset(0, 0),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===================== IMAGE SECTION =====================
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: const Color(0xFFD9D9D9),
                image: (displayImage.isNotEmpty)
                    ? DecorationImage(
                        image: NetworkImage(displayImage),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: (displayImage.isEmpty)
                  ? const Center(child: Icon(Icons.image_not_supported, color: Colors.white54))
                  : null,
            ),
            
            const SizedBox(height: 15),

            // ===================== TEXT SECTION =====================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4), 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    event.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                      color: Colors.black,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 6),
                  
                  // Date & Time
                  Row(
                    children: [
                      Text(
                        dateFormatted,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF594AFC),
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        width: 3, height: 3,
                        decoration: const BoxDecoration(color: Color(0xFF594AFC), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        timeFormatted,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF594AFC),
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 7),
                  
                  // Location
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Color(0xFF777777)),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          event.location,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF777777),
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
    );
  }
}