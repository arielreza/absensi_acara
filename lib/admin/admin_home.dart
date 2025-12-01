// lib/admin/admin_home.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/attendance.dart';

import 'scan_screen.dart';
import 'attendance_history.dart';
import 'event_management_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_event_screen.dart';



class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  void _showLogoutDialog(BuildContext context, AuthService auth) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              auth.signOut();
            },
            child: const Text('Ya, Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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
            // small header with avatar + subtitle
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.person, size: 34, color: Colors.deepPurple),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Admin Dashboard 👋",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text("Manage your events and participants", style: TextStyle(color: Colors.black54)),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // STAT CARDS (4)
            _statsSection(),

            const SizedBox(height: 22),

            // Quick Actions label
            const Text("Quick Actions", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),

            // Quick action list
            SizedBox(
              height: 106,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _quickActionTile(Icons.qr_code_scanner, "Scan QR", () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanScreen()));
                  }),
                  _quickActionTile(Icons.people_alt, "Participant\nManagement", () {
                    // future: navigate to participants screen
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Participant Management (TODO)")));
                  }),
                  _quickActionTile(Icons.event, "Event\nManagement", () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const EventManagementScreen()));
                  }),
                  _quickActionTile(Icons.insert_drive_file, "Attendance\nReport", () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceHistoryScreen()));
                  }),
                  _quickActionTile(Icons.upload_file, "Export\nData", () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Export Data (TODO)")));
                  }),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // Active Events label
            const Text("Active Events", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),

            // Active event card (placeholder)
            _activeEventsSection(context),
            const SizedBox(height: 30),
          ],
        ),
      ),

      // bottom navigation (simple)
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: "Event"),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: "Scan"),
        ],
        onTap: (index) {
          // simple navigation behavior: if user taps Event or Scan, navigate
          if (index == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const EventManagementScreen()));
          } else if (index == 2) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanScreen()));
          }
        },
      ),
    );
  }

  // ---------------- UI Components ----------------

  Widget _statsSection() {
    // grid with 2 rows x 2 columns
    return FutureBuilder<List<Attendance>>(
      future: DatabaseService().getAttendanceHistory(),
      builder: (context, snapshot) {
        final total = snapshot.data?.length ?? 248; // fallback dummy
        return Column(
          children: [
            Row(
              children: [
                _statCard(total.toString(), "Total Participant", Colors.blue.shade50, Colors.indigo),
                const SizedBox(width: 12),
                _statCard("187", "Checked-in", Colors.orange.shade50, Colors.orange),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _statCard("61", "Not Checked-in", Colors.green.shade50, Colors.green),
                const SizedBox(width: 12),
                _statCard("3", "Active Event", Colors.purple.shade50, Colors.purple),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _statCard(String value, String label, Color bg, Color accent) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: accent)),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  Widget _quickActionTile(IconData icon, String label, VoidCallback onTap) {
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
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6)],
              ),
              child: Icon(icon, size: 30, color: Colors.deepPurple),
            ),
          ),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

Widget _activeEventsSection(BuildContext context) {
  return StreamBuilder(
    stream: FirebaseFirestore.instance
        .collection("events")
        .where("is_active", isEqualTo: true)
        .orderBy("event_date")
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
          style: TextStyle(color: Colors.black54),
        );
      }

      return Column(
        children: docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final Timestamp ts = data["event_date"];
          final date = ts.toDate();
          final eventId = doc.id;

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
                // Poster
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text("Event Poster Placeholder", style: TextStyle(color: Colors.white)),
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  data["event_name"] ?? "-",
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 6),

                Text(
                  "${date.day}/${date.month}/${date.year} • ${data["location"]}",
                  style: const TextStyle(color: Colors.black54),
                ),

                const SizedBox(height: 8),

                Row(
                  children: const [
                    Icon(Icons.person, size: 16, color: Colors.blueGrey),
                    SizedBox(width: 6),
                    Text("Active Event"),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditEventScreen(eventId: eventId),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("Edit Event"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Icon(Icons.share),
                    )
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      );
    },
  );
}



  Widget _activeEventCardPlaceholder(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // poster placeholder
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: Text("Event Poster Placeholder", style: TextStyle(color: Colors.white))),
          ),
          const SizedBox(height: 12),
          const Text(
            "Sustainability Program: Dorong Kemandirian atau Ketergantungan?",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text("Sat, Apr 8 • 9.00 AM – 12.00 PM\nAuditorium Lantai 8", style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 8),
          Row(
            children: const [
              Icon(Icons.person, size: 16, color: Colors.blueGrey),
              SizedBox(width: 6),
              Text("127/150 Participant"),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // go to event detail or edit (placeholder)
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const EventManagementScreen()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("View Event Details"),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: () {
                  // optional quick action
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Share / Export (TODO)")));
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Icon(Icons.share),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
