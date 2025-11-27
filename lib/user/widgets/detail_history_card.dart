import 'package:absensi_acara/models/absence.dart';
import 'package:absensi_acara/models/event.dart';
import 'package:absensi_acara/models/user.dart';
import 'package:absensi_acara/user/screens/detail_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

class DetailHistoryCard extends StatelessWidget {
  final Absence absence;
  final Event event;
  final User user;

  const DetailHistoryCard({
    super.key,
    required this.absence,
    required this.event,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    // print(user.name);

    // Format time and date
    final eventDateTime = (event.date as dynamic).toDate() as DateTime;
    final timeFormat = DateFormat('HH:mm').format(eventDateTime);
    final dateFormat = DateFormat('EEEE, dd MMMM yyyy').format(eventDateTime);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Column(
        children: [
          // SECTION CARD 1 (Event details)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    "assets/ticket_header.png",
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  event.name,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, height: 1.3),
                ),

                const SizedBox(height: 16),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          DetailColumn(title: "Name", value: user.name),
                          DetailColumn(title: "NIM", value: user.nim),
                        ],
                      ),
                      const SizedBox(height: 18),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          DetailColumn(title: "Time", value: timeFormat),
                          DetailColumn(title: "Date", value: dateFormat),
                        ],
                      ),

                      const SizedBox(height: 18),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: DetailColumn(title: "Place", value: event.location, fullWidth: true),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // SECTION CARD 2 (QR Code)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    const Text(
                      "Scan this QR Code\nor show this ticket\nat webinar",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                    const SizedBox(height: 16),
                    const Text("Ticket ID", style: TextStyle(color: Colors.grey)),
                    Text(
                      absence.id,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                QrImageView(data: absence.id, version: QrVersions.auto, size: 180),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
