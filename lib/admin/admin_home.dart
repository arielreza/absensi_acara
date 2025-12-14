// lib/admin/admin_home.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/attendance.dart';

import 'scan_screen.dart';
import 'attendance_history.dart';
import 'event_management_screen.dart';
import 'edit_event_screen.dart';

import 'dart:io';
import 'package:excel/excel.dart' as excel_package;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

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
                  child: const Icon(Icons.person, size: 34, color: Colors.deepPurple),
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Coming Soon")),
                    );
                  }),
                  _quickActionTile(Icons.event, "Event\nManagement", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EventManagementScreen()),
                    );
                  }),
                  _quickActionTile(Icons.insert_drive_file, "Attendance\nReport", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AttendanceHistoryScreen()),
                    );
                  }),
                  _quickActionTile(Icons.upload_file, "Export\nData", () {
                    _handleExportData(context);
                  }),
                ],
              ),
            ),

            const SizedBox(height: 22),

            const Text(
              "Active Events",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
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
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: "Event"),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: "Scan"),
        ],
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EventManagementScreen()),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ScanScreen()),
            );
          }
        },
      ),
    );
  }

  // ===================== FUNGSI EKSPOR DATA (MOBILE ONLY) =====================
  Future<void> _handleExportData(BuildContext context) async {
    final dialogContext = context;
    
    // Tampilkan loading dialog
    showDialog(
      context: dialogContext,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text("Mengekspor data...", style: TextStyle(fontFamily: 'Poppins')),
          ],
        ),
      ),
    );

    try {
      debugPrint('=== MULAI EKSPOR DATA MOBILE ===');
      
      // 1. Cek autentikasi
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        Navigator.pop(dialogContext);
        _showSnackbar(dialogContext, 'Harus login terlebih dahulu', Colors.orange);
        return;
      }
      
      // 2. Ambil data absences
      debugPrint('Mengambil data dari Firestore...');
      final absenceSnapshot = await FirebaseFirestore.instance
          .collection('absences')
          .get();
      
      debugPrint('Jumlah data ditemukan: ${absenceSnapshot.docs.length}');
      
      if (absenceSnapshot.docs.isEmpty) {
        Navigator.pop(dialogContext);
        _showSnackbar(dialogContext, 'Tidak ada data absensi untuk diekspor', Colors.orange);
        return;
      }
      
      // 3. Ambil data users dan events untuk referensi
      final usersData = await _fetchUsersData(absenceSnapshot);
      final eventsData = await _fetchEventsData(absenceSnapshot);
      
      // 4. Buat file Excel
      debugPrint('Membuat file Excel...');
      final excel = excel_package.Excel.createExcel();
      final sheet = excel['Riwayat Absensi'];
      
      // Header
      sheet.appendRow([
        'ID Absensi',
        'User ID',
        'Nama User',
        'Email User',
        'Event ID',
        'Nama Event',
        'Waktu Absensi',
        'Status',
        'Tanggal (DD/MM/YYYY)'
      ]);
      
      // 5. Proses data
      int processedCount = 0;
      
      for (var doc in absenceSnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final docId = doc.id;
          final eventId = data['event_id']?.toString() ?? '';
          final userId = data['user_id']?.toString() ?? '';
          
          // Ambil nama user
          String userName = 'User Tidak Ditemukan';
          String userEmail = '-';
          if (userId.isNotEmpty && usersData.containsKey(userId)) {
            final user = usersData[userId]!;
            userName = user['name'] ?? 
                      user['full_name'] ?? 
                      user['username'] ?? 
                      user['displayName'] ?? 
                      'User ID: $userId';
            userEmail = user['email'] ?? '-';
          } else if (userId.isNotEmpty) {
            userName = 'User ID: $userId';
          }
          
          // Ambil nama event
          String eventName = 'Event Tidak Ditemukan';
          if (eventId.isNotEmpty && eventsData.containsKey(eventId)) {
            final event = eventsData[eventId]!;
            eventName = event['event_name'] ?? 
                      event['title'] ?? 
                      event['name'] ?? 
                      'Event ID: $eventId';
          } else if (eventId.isNotEmpty) {
            eventName = 'Event ID: $eventId';
          }
          
          // Parse waktu
          String timeStr = 'Belum absen';
          String dateStr = '';
          
          // Cari field timestamp
          final timestamp = _parseTimestamp(data);
          if (timestamp != null) {
            final date = timestamp.toDate();
            timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
            dateStr = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
          }
          
          // Status
          final status = data['status']?.toString() ?? 'hadir';
          
          // Tambahkan ke Excel
            sheet.appendRow([
            docId,
            userId,
            userName,
            userEmail,
            eventId,
            eventName,
            timeStr,
            status,
            dateStr,
          ]);
          
          processedCount++;
          
        } catch (e) {
          debugPrint('Error processing document ${doc.id}: $e');
        }
      }
      
      // 6. Simpan file
      final excelBytes = excel.save();
      if (excelBytes == null) {
        throw Exception('Gagal membuat file Excel');
      }
      
      // 7. Simpan ke storage mobile
      final directory = await getExternalStorageDirectory();
      final downloadsDir = Directory('/storage/emulated/0/Download');
      
      Directory targetDir;
      if (downloadsDir.existsSync()) {
        targetDir = downloadsDir;
      } else if (directory != null) {
        targetDir = directory;
      } else {
        targetDir = await getTemporaryDirectory();
      }
      
      final fileName = 'riwayat_absensi_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final filePath = '${targetDir.path}/$fileName';
      
      final file = File(filePath);
      await file.writeAsBytes(excelBytes);
      
      // 8. Buka file
      await OpenFilex.open(filePath);
      
      // 9. Tampilkan hasil
      Navigator.pop(dialogContext);
      
      _showSnackbar(
        dialogContext,
        '$processedCount data berhasil diekspor\nFile tersimpan di: ${targetDir.path}',
        Colors.green,
        duration: 5,
      );
      
    } catch (e) {
      Navigator.pop(dialogContext);
      
      debugPrint('ERROR: $e');
      
      _showSnackbar(
        dialogContext,
        'Gagal mengekspor: ${e.toString()}',
        Colors.red,
        duration: 5,
      );
    }
  }

  Future<Map<String, Map<String, dynamic>>> _fetchUsersData(QuerySnapshot absenceSnapshot) async {
    final Map<String, Map<String, dynamic>> usersData = {};
    final Set<String> userIds = {};
    
    // Kumpulkan semua user ID
    for (var doc in absenceSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final userId = data['user_id']?.toString() ?? '';
      if (userId.isNotEmpty) userIds.add(userId);
    }
    
    if (userIds.isEmpty) return usersData;
    
    // Ambil data users (batch untuk efisiensi)
    try {
      final userIdList = userIds.toList();
      for (var i = 0; i < userIdList.length; i += 10) {
        final batch = userIdList.sublist(
          i, 
          i + 10 > userIdList.length ? userIdList.length : i + 10
        );
        
        final usersSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        
        for (var doc in usersSnapshot.docs) {
          usersData[doc.id] = doc.data() as Map<String, dynamic>;
        }
      }
    } catch (e) {
      debugPrint('Error fetching users: $e');
    }
    
    return usersData;
  }

  Future<Map<String, Map<String, dynamic>>> _fetchEventsData(QuerySnapshot absenceSnapshot) async {
    final Map<String, Map<String, dynamic>> eventsData = {};
    final Set<String> eventIds = {};
    
    // Kumpulkan semua event ID
    for (var doc in absenceSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final eventId = data['event_id']?.toString() ?? '';
      if (eventId.isNotEmpty) eventIds.add(eventId);
    }
    
    if (eventIds.isEmpty) return eventsData;
    
    // Ambil data events
    try {
      final eventIdList = eventIds.toList();
      for (var i = 0; i < eventIdList.length; i += 10) {
        final batch = eventIdList.sublist(
          i, 
          i + 10 > eventIdList.length ? eventIdList.length : i + 10
        );
        
        final eventsSnapshot = await FirebaseFirestore.instance
            .collection('events')
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        
        for (var doc in eventsSnapshot.docs) {
          eventsData[doc.id] = doc.data() as Map<String, dynamic>;
        }
      }
    } catch (e) {
      debugPrint('Error fetching events: $e');
    }
    
    return eventsData;
  }

  Timestamp? _parseTimestamp(Map<String, dynamic> data) {
    // Coba berbagai field yang mungkin berisi timestamp
    final possibleFields = [
      'absence_time',
      'check_in_time',
      'timestamp',
      'created_at',
      'time',
      'attendance_time',
      'date'
    ];
    
    for (var field in possibleFields) {
      final value = data[field];
      if (value == null) continue;
      
      if (value is Timestamp) {
        print('Found timestamp in field: $field');
        return value;
      } else if (value is Map) {
        final map = value as Map<String, dynamic>;
        if (map['_seconds'] != null && map['_nanoseconds'] != null) {
          print('Found timestamp map in field: $field');
          return Timestamp(map['_seconds'] as int, map['_nanoseconds'] as int);
        }
      } else if (value is String) {
        final date = DateTime.tryParse(value);
        if (date != null) {
          print('Found date string in field: $field = $date');
          return Timestamp.fromDate(date);
        }
      }
    }
    
    print('No timestamp found in data. Available fields: ${data.keys.join(", ")}');
    return null;
  }

  void _showSnackbar(BuildContext context, String message, Color color, {int duration = 3}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Poppins')),
        backgroundColor: color,
        duration: Duration(seconds: duration),
      ),
    );
  }

  Widget _statsSection() {
    return FutureBuilder<List<Attendance>>(
      future: DatabaseService().getAttendanceHistory(),
      builder: (context, snapshot) {
        final total = snapshot.data?.length ?? 248;

        return Column(
          children: [
            Row(
              children: [
                _statCard(
                  total.toString(),
                  "Total Participant",
                  Colors.blue.shade50,
                  Colors.indigo,
                ),
                const SizedBox(width: 12),
                _statCard("187", "Checked-in", Colors.orange.shade50, Colors.orange),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _statCard("61", "Not Checked-in", Colors.green.shade50, Colors.green),
                const SizedBox(width: 12),
                FutureBuilder<int>(
                  future: _countActiveEvents(),
                  builder: (context, snap) {
                    final active = snap.data ?? 0;
                    return _statCard(
                      active.toString(),
                      "Active Event",
                      Colors.purple.shade50,
                      Colors.purple,
                    );
                  },
                )
              ],
            )
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
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: accent,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
                fontFamily: 'Poppins',
              ),
            ),
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
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6)
                ],
              ),
              child: Icon(icon, size: 30, color: Colors.deepPurple),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontFamily: 'Poppins'),
          ),
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
                  // ===================== EVENT IMAGE =====================
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
                                  child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
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
                          child: const Text(
                            "Edit Event",
                            style: TextStyle(fontFamily: 'Poppins'),
                          ),
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