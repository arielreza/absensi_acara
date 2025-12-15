// lib/admin/admin_home.dart
// UPDATE: Menambahkan navigasi ke Participant Management Screen

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:excel/excel.dart' as excel_package;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/attendance.dart';

import 'scan_screen.dart';
import 'attendance_history.dart';
import 'event_management_screen.dart';
import 'edit_event_screen.dart';
import 'participant_management_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  Future<int> _countActiveEvents() async {
    final snap = await FirebaseFirestore.instance
        .collection("events")
        .where("is_active", isEqualTo: true)
        .get();

    return snap.docs.length;
  }

  void _showLogoutDialog(BuildContext context, AuthService auth) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout', style: TextStyle(fontFamily: 'Poppins')),
        content: const Text(
          'Apakah Anda yakin ingin keluar?',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal', style: TextStyle(fontFamily: 'Poppins'))),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              auth.signOut();
            },
            child: const Text(
              'Ya, Logout',
              style: TextStyle(color: Colors.red, fontFamily: 'Poppins'),
            ),
          ),
        ],
      ),
    );
  }

  Color _progressColor(double v) {
    if (v < 0.33) return Colors.green;
    if (v < 0.66) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Admin Dashboard 👋",
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context, auth),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 34,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Admin Dashboard 👋",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Manage your events and participants",
                        style: TextStyle(
                          color: Colors.black54,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            _statsSection(),

            const SizedBox(height: 22),

            const Text(
              "Quick Actions",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              height: 106,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _quickActionTile(Icons.qr_code_scanner, "Scan QR", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ScanScreen()),
                    );
                  }),
                  _quickActionTile(Icons.people_alt, "Participant\nManagement", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ParticipantManagementScreen()),
                    );
                  }),
                  _quickActionTile(Icons.event, "Event\nManagement", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EventManagementScreen(),
                      ),
                    );
                  }),
                  _quickActionTile(
                    Icons.insert_drive_file,
                    "Attendance\nReport",
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AttendanceHistoryScreen(),
                        ),
                      );
                    },
                  ),
                  _quickActionTile(Icons.upload_file, "Export\nData", () {
                    _exportAttendanceData(context);
                  }),
                ],
              ),
            ),

            const SizedBox(height: 22),

            const Text(
              "Upcoming Events",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 12),

            _upcomingEvents(context),
          ],
        ),
      ),
    );
  }

  Widget _statsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("events").snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        int totalEvents = 0;
        int totalParticipants = 0;

        if (snapshot.hasData) {
          totalEvents = snapshot.data!.docs.length;
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            totalParticipants += (data['participants_count'] ?? 0) as int;
          }
        }

        return Row(
          children: [
            Expanded(
              child: _statCard(
                icon: Icons.event,
                label: "Total Events",
                value: totalEvents.toString(),
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                icon: Icons.people,
                label: "Total Participants",
                value: totalParticipants.toString(),
                color: Colors.green,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportAttendanceData(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Exporting data...'),
          ],
        ),
      ),
    );

    try {
      final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in')),
        );
        return;
      }

      // Fetch absences
      final absenceSnapshot = await FirebaseFirestore.instance
          .collection('absences')
          .orderBy('absence_time', descending: true)
          .get();

      if (absenceSnapshot.docs.isEmpty) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No attendance data to export')),
        );
        return;
      }

      // Fetch related user and event data
      final usersData = await _fetchUsersData(absenceSnapshot);
      final eventsData = await _fetchEventsData(absenceSnapshot);

      // Create Excel
      final excel = excel_package.Excel.createExcel();
      final sheet = excel['Attendance Data'];

      // Headers
      sheet.appendRow([
        'No',
        'Nama',
        'NIM',
        'Email',
        'Event',
        'Lokasi',
        'Status',
        'Waktu Absen',
      ]);

      // Data rows
      int no = 1;
      for (var doc in absenceSnapshot.docs) {
        final data = doc.data();
        final userId = data['user_id'] ?? '';
        final eventId = data['event_id'] ?? '';
        final status = data['status'] ?? '';
        final absenceTime = data['absence_time'] as Timestamp?;

        final userName = usersData[userId]?['name'] ?? 'Unknown';
        final userNim = usersData[userId]?['nim'] ?? '-';
        final userEmail = usersData[userId]?['email'] ?? '-';
        final eventName = eventsData[eventId]?['event_name'] ?? 'Unknown Event';
        final eventLocation = eventsData[eventId]?['location'] ?? '-';

        String absenceTimeStr = '-';
        if (absenceTime != null) {
          final dt = absenceTime.toDate();
          absenceTimeStr =
              '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
        }

        sheet.appendRow([
          no,
          userName,
          userNim,
          userEmail,
          eventName,
          eventLocation,
          status,
          absenceTimeStr,
        ]);

        no++;
      }

      // Save file
      final excelBytes = excel.encode();
      if (excelBytes == null) {
        throw Exception('Failed to encode Excel file');
      }

      // Get directory
      final directory = await getExternalStorageDirectory();
      final downloadsDir = Directory('/storage/emulated/0/Download');

      Directory targetDir;
      if (await downloadsDir.exists()) {
        targetDir = downloadsDir;
      } else {
        targetDir = await getTemporaryDirectory();
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'attendance_data_$timestamp.xlsx';
      final filePath = '${targetDir.path}/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(excelBytes);

      // Open file
      await OpenFilex.open(filePath);

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('File saved to: $filePath'),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      debugPrint('Error exporting data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<Map<String, Map<String, dynamic>>> _fetchUsersData(
      QuerySnapshot absenceSnapshot) async {
    final userIds =
        absenceSnapshot.docs.map((doc) => doc['user_id'] as String).toSet();
    final usersData = <String, Map<String, dynamic>>{};

    for (var userId in userIds) {
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (userDoc.exists) {
        usersData[userId] = userDoc.data() ?? {};
      }
    }

    return usersData;
  }

  Future<Map<String, Map<String, dynamic>>> _fetchEventsData(
      QuerySnapshot absenceSnapshot) async {
    final eventIds =
        absenceSnapshot.docs.map((doc) => doc['event_id'] as String).toSet();
    final eventsData = <String, Map<String, dynamic>>{};

    for (var eventId in eventIds) {
      final eventDoc = await FirebaseFirestore.instance
          .collection('events')
          .doc(eventId)
          .get();
      if (eventDoc.exists) {
        eventsData[eventId] = eventDoc.data() ?? {};
      }
    }

    return eventsData;
  }

  Widget _quickActionTile(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.deepPurple.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.deepPurple.shade100),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Colors.deepPurple),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
                color: Colors.deepPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _upcomingEvents(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("events")
          .where("is_active", isEqualTo: true)
          .orderBy("event_date", descending: false)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final QuerySnapshot? snap = snapshot.data as QuerySnapshot?;
        final docs = snap?.docs ?? [];

        if (docs.isEmpty) {
          return const Text(
            "No Active Events",
            style: TextStyle(color: Colors.black54, fontFamily: 'Poppins'),
          );
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final date = (data["event_date"] as Timestamp).toDate();

            final String eventId = doc.id;
            final String imageUrl = data["image_url"] ?? '';

            final int quota = data["participants"] ?? 0;
            final int count = data["participants_count"] ?? 0;
            final double progress = quota == 0 ? 0 : count / quota;

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                height: 150,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.deepPurple,
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 150,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                ),
                              );
                            },
                          )
                        : Container(
                            height: 150,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text(
                                "Event Poster Placeholder",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    data["event_name"],
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    "${date.day}/${date.month}/${date.year} • ${data["location"]}",
                    style: const TextStyle(
                      color: Colors.black54,
                      fontFamily: 'Poppins',
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Progress bar
                  Container(
                    height: 8,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress.clamp(0, 1),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _progressColor(progress),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    "$count / $quota participants",
                    style: const TextStyle(fontSize: 12, fontFamily: 'Poppins'),
                  ),

                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    EditEventScreen(eventId: eventId),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: const Text(
                            "Edit Event",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Icon(Icons.share),
                      )
                    ],
                  )
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}