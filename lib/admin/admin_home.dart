// lib/admin/admin_home.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/attendance.dart';

import 'scan_screen.dart';
import 'attendance_history.dart';
import 'event_management_screen.dart';
import 'edit_event_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  // Hitung jumlah active events
  Future<int> _countActiveEvents() async {
    final snap = await FirebaseFirestore.instance
        .collection("events")
        .where("is_active", isEqualTo: true)
        .get();

    return snap.docs.length;
  }

  // Logout dialog
  void _showLogoutDialog(BuildContext context, AuthService auth) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal')),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              auth.signOut();
            },
            child: const Text('Ya, Logout',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Progress bar color logic
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
          style: TextStyle(fontWeight: FontWeight.bold),
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
                  child: const Icon(Icons.person,
                      size: 34, color: Colors.deepPurple),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Admin Dashboard 👋",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text("Manage your events and participants",
                          style: TextStyle(color: Colors.black54)),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // STAT
            _statsSection(),

            const SizedBox(height: 22),

            const Text("Quick Actions",
                style:
                    TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),

            SizedBox(
              height: 106,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _quickActionTile(Icons.qr_code_scanner, "Scan QR", () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ScanScreen()));
                  }),
                  _quickActionTile(Icons.people_alt,
                      "Participant\nManagement", () {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Coming Soon")));
                  }),
                  _quickActionTile(Icons.event, "Event\nManagement", () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const EventManagementScreen()));
                  }),
                  _quickActionTile(Icons.insert_drive_file,
                      "Attendance\nReport", () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const AttendanceHistoryScreen()));
                  }),
                  _quickActionTile(Icons.upload_file, "Export\nData", () {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Coming Soon")));
                  }),
                ],
              ),
            ),

            const SizedBox(height: 22),

            const Text("Active Events",
                style:
                    TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),

            _activeEventsSection(context),
            const SizedBox(height: 30),
          ],
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_filled), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.event), label: "Event"),
          BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner), label: "Scan"),
        ],
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const EventManagementScreen()));
          } else if (index == 2) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ScanScreen()));
          }
        },
      ),
    );
  }

  // -----------------------------------------------
  // STATS SECTION
  // -----------------------------------------------
  Widget _statsSection() {
    return FutureBuilder<List<Attendance>>(
      future: DatabaseService().getAttendanceHistory(),
      builder: (context, snapshot) {
        final total = snapshot.data?.length ?? 248;

        return Column(
          children: [
            Row(
              children: [
                _statCard(total.toString(), "Total Participant",
                    Colors.blue.shade50, Colors.indigo),
                const SizedBox(width: 12),
                _statCard("187", "Checked-in",
                    Colors.orange.shade50, Colors.orange),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _statCard("61", "Not Checked-in",
                    Colors.green.shade50, Colors.green),
                const SizedBox(width: 12),
                FutureBuilder<int>(
                  future: _countActiveEvents(),
                  builder: (context, snap) {
                    final active = snap.data ?? 0;
                    return _statCard(active.toString(), "Active Event",
                        Colors.purple.shade50, Colors.purple);
                  },
                )
              ],
            )
          ],
        );
      },
    );
  }

  Widget _statCard(
      String value, String label, Color bg, Color accent) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: accent)),
            const SizedBox(height: 8),
            Text(label,
                style:
                    const TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  Widget _quickActionTile(
      IconData icon, String label, VoidCallback onTap) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 6)
                ],
              ),
              child: Icon(icon,
                  size: 30, color: Colors.deepPurple),
            ),
          ),
          const SizedBox(height: 8),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  // -----------------------------------------------
  // ACTIVE EVENTS SECTION
  // -----------------------------------------------
  Widget _activeEventsSection(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection("events")
          .where("is_active", isEqualTo: true)
          .orderBy("event_date")
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final QuerySnapshot? snap =
            snapshot.data as QuerySnapshot?;
        final docs = snap?.docs ?? [];

        if (docs.isEmpty) {
          return const Text("No Active Events",
              style: TextStyle(color: Colors.black54));
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final date = (data["event_date"] as Timestamp).toDate();

            final String eventId = doc.id;

            final int quota = data["participants"] ?? 0;
            final int count = data["participants_count"] ?? 0;
            final double progress =
                quota == 0 ? 0 : count / quota;

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
                      offset: const Offset(0, 3))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Poster placeholder
                  Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text("Event Poster Placeholder",
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    data["event_name"],
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    "${date.day}/${date.month}/${date.year} • ${data["location"]}",
                    style:
                        const TextStyle(color: Colors.black54),
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
                    style: const TextStyle(fontSize: 12),
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
                                        EditEventScreen(
                                            eventId: eventId)));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            padding: const EdgeInsets.symmetric(
                                vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12)),
                          ),
                          child: const Text("Edit Event"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
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
