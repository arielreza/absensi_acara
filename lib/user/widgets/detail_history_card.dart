import 'dart:convert';

import 'package:absensi_acara/models/absence.dart';
import 'package:absensi_acara/models/event.dart';
import 'package:absensi_acara/models/user.dart';
import 'package:absensi_acara/user/screens/detail_history_screen.dart';
import 'package:absensi_acara/user/widgets/placeholder_image.dart';
import 'package:absensi_acara/user/service/event_register_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

class DetailHistoryCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    // Format time and date
    final eventDateTime = (event.date as dynamic).toDate() as DateTime;
    final timeFormat = DateFormat('hh:mm').format(eventDateTime);
    final dateFormat = DateFormat('dd MMM yyyy').format(eventDateTime);

    // Test apakah JSON yang dihasilkan valid
    Widget buildQrCodeWithDebug() {
      final qrData = jsonEncode({
        "user_id": user.id.toString(),
        "event_id": event.id.toString(),
      });

      return Column(
        children: [
          QrImageView(
            data: absence.id,
            version: QrVersions.auto,
            size: 180,
            backgroundColor: Colors.white,
            errorCorrectionLevel: QrErrorCorrectLevel.H,
          ),
        ],
      );
    }

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
                event.imageUrl.isNotEmpty
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

                const SizedBox(height: 14),

                Text(
                  event.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          DetailColumn(title: "Name", value: user.name),
                          DetailColumn(title: "NIM", value: user.nim),
                        ],
                      ),

                      // const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          DetailColumn(title: "Time", value: timeFormat),
                          DetailColumn(title: "Date", value: dateFormat),
                        ],
                      ),

                      // const SizedBox(height: 18),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: DetailColumn(
                          title: "Place",
                          value: event.location,
                          fullWidth: true,
                        ),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            "Scan this QR Code\nor show this ticket\nat webinar",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Ticket ID",
                            style: TextStyle(color: Colors.grey),
                          ),
                          Text(
                            absence.id,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(child: buildQrCodeWithDebug()),
                  ],
                ),
                const SizedBox(height: 16),
                // Cancel / Unregister button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text('Batalkan Pendaftaran'),
                          content: const Text(
                            'Anda yakin ingin membatalkan pendaftaran untuk event ini?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(c).pop(false),
                              child: const Text('BATAL'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.of(c).pop(true),
                              child: const Text('YA'),
                            ),
                          ],
                        ),
                      );

                      if (confirm != true) return;

                      try {
                        await ref
                            .read(eventRegisterService)
                            .unregisterEvent(
                              eventId: event.id,
                              userId: user.id,
                              absenceId: absence.id,
                            );

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Pendaftaran dibatalkan'),
                            ),
                          );
                          Navigator.of(context).pop();
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
                      }
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Batalkan Pendaftaran',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
