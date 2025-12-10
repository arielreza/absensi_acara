import 'package:absensi_acara/models/event.dart';
import 'package:absensi_acara/user/screens/detail_event_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class EventCard extends ConsumerWidget {
  final Event event;
  final String eventId;
  final String? imageUrl;
  final String userId;

  const EventCard({
    super.key,
    required this.event,
    required this.eventId,
    required this.imageUrl,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    DateTime eventDate = (event.date).toDate();

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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Color(0x19000000), blurRadius: 6, offset: Offset(0, 0)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Image
            Container(
              height: 135,
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFD9D9D9),
                borderRadius: BorderRadius.circular(20),
                image: imageUrl != null && imageUrl!.isNotEmpty
                    ? DecorationImage(image: NetworkImage(imageUrl!), fit: BoxFit.cover)
                    : null,
              ),
              child: (imageUrl == null || imageUrl!.isEmpty)
                  ? const Center(child: Icon(Icons.event, size: 40, color: Colors.white54))
                  : null,
            ),

            // Event Details
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.name,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  Row(
                    children: [
                      Text(
                        _formatDate(eventDate),
                        style: const TextStyle(
                          color: Color(0xFF594AFC),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: const BoxDecoration(
                          color: Color(0xFF594AFC),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          _formatTime(eventDate),
                          style: const TextStyle(
                            color: Color(0xFF594AFC),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Color(0xFF777777)),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          event.location,
                          style: const TextStyle(
                            color: Color(0xFF777777),
                            fontSize: 12,
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

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

// --- Helper ---
String _formatDate(DateTime date) {
  return DateFormat('d MMM yyyy', 'id_ID').format(date);
}

String _formatTime(DateTime date) {
  return DateFormat('HH:mm').format(date);
}
