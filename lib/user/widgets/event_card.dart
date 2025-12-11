import 'package:absensi_acara/models/event.dart';
import 'package:absensi_acara/user/screens/detail_event_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class EventCard extends ConsumerWidget {
  final Event event;
  final String eventId;
  final String userId;

  const EventCard({
    super.key,
    required this.event,
    required this.eventId,
    required this.userId,
    String? imageUrl,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DateTime eventDate = event.date.toDate();

    final String dateFormatted = _formatDate(eventDate);
    final String timeFormatted = _formatTime(eventDate);

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
            // ===================== IMAGE SECTION =====================
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: (event.imageUrl.isNotEmpty)
                  ? Image.network(
                      event.imageUrl,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 160,
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(color: Color(0xFF594AFC)),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return _buildPlaceholderImage();
                      },
                    )
                  : _buildPlaceholderImage(),
            ),

            // ===================== CONTENT SECTION =====================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event Title
                  Text(
                    event.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // Date & Time
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          "$dateFormatted   •   $timeFormatted",
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Location
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Color(0xFF777777)),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          event.location,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                            fontFamily: 'Poppins',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ===================== BUTTON =====================
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetailEventScreen(eventId: eventId, userId: userId),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF594AFC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'View Details',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // Placeholder image
  Widget _buildPlaceholderImage() {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF594AFC).withOpacity(0.7),
            const Color(0xFF594AFC).withOpacity(0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(child: Icon(Icons.event, size: 60, color: Colors.white)),
    );
  }
}

String _formatDate(DateTime date) {
  return DateFormat('d MMM yyyy', 'id_ID').format(date);
}

String _formatTime(DateTime date) {
  return DateFormat('HH:mm').format(date);
}
