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
import 'package:universal_io/io.dart' as uio;

import 'dart:convert';
import 'dart:html' as html;

import 'dart:math' as math;

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  int _min(int a, int b) => a < b ? a : b;

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
                  _quickActionTile(Icons.upload_file, "Export\nData", () async {
                    final dialogContext = context;
                    showDialog(
                      context: dialogContext,
                      barrierDismissible: false,
                      builder: (context) => const AlertDialog(
                        content: Row(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(width: 16),
                            Text("Mengekspor dari Firestore...", style: TextStyle(fontFamily: 'Poppins')),
                          ],
                        ),
                      ),
                    );

                    try {
                      print('=== MULAI EKSPOR DARI FIRESTORE ===');
                      
                      // 1. CEK AUTENTIKASI DULU
                      final currentUser = FirebaseAuth.instance.currentUser;
                      if (currentUser == null) {
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(
                            content: Text('Harus login terlebih dahulu',
                                        style: TextStyle(fontFamily: 'Poppins')),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }
                      
                      print('User logged in: ${currentUser.uid}');
                      
                      // 2. TEST QUERY SEDERHANA DULU
                      print('Testing Firestore connection...');
                      try {
                        final testQuery = await FirebaseFirestore.instance
                            .collection('events')
                            .limit(1)
                            .get();
                        print('Firestore connection OK');
                      } catch (e) {
                        print('Firestore connection failed: $e');
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(
                            content: Text('Koneksi Firestore gagal: ${e.toString()}',
                                        style: TextStyle(fontFamily: 'Poppins')),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      
                      // 3. AMBIL DATA DARI COLLECTION "absences"
                      print('Mengambil data dari koleksi "absences"...');
                      QuerySnapshot absenceSnapshot;
                      
                      try {
                        absenceSnapshot = await FirebaseFirestore.instance
                            .collection('absences')
                            .get();
                        
                        print('Berhasil ambil ${absenceSnapshot.docs.length} data dari absences');
                        
                      } catch (e) {
                        print('Gagal ambil dari absences: $e');
                        
                        // Fallback: coba collection lain atau tampilkan error spesifik
                        Navigator.pop(dialogContext);
                        
                        if (e.toString().contains('permission-denied')) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            const SnackBar(
                              content: Text('Izin ditolak!\nPeriksa Firestore Rules untuk koleksi "absences"',
                                          style: TextStyle(fontFamily: 'Poppins')),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 5),
                            ),
                          );
                        } else if (e.toString().contains('network')) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            const SnackBar(
                              content: Text('Gagal koneksi jaringan\nCek koneksi internet Anda',
                                          style: TextStyle(fontFamily: 'Poppins')),
                              backgroundColor: Colors.red,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${e.toString()}',
                                          style: TextStyle(fontFamily: 'Poppins')),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                        return;
                      }
                      
                      // 4. CEK JIKA DATA KOSONG
                      if (absenceSnapshot.docs.isEmpty) {
                        Navigator.pop(dialogContext);
                        
                        // Debug: cek koleksi lain untuk pastikan Firestore berfungsi
                        try {
                          final eventsCount = await FirebaseFirestore.instance
                              .collection('events')
                              .count()
                              .get();
                          print('Events count: ${eventsCount.count}');
                          
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Koleksi "absences" kosong',
                                            style: TextStyle(fontFamily: 'Poppins')),
                                  Text('Data events tersedia: ${eventsCount.count}',
                                      style: const TextStyle(fontSize: 12)),
                                  const Text('Pastikan sudah ada data absensi',
                                          style: TextStyle(fontSize: 12)),
                                ],
                              ),
                              backgroundColor: Colors.orange,
                              duration: const Duration(seconds: 4),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            const SnackBar(
                              content: Text('Tidak ada data di koleksi "absences"',
                                          style: TextStyle(fontFamily: 'Poppins')),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                        return;
                      }
                      
                      // 5. DEBUG: TAMPILKAN STRUKTUR DATA
                      print('=== STRUKTUR DATA ABSENCES ===');
                      for (var i = 0; i < _min(2, absenceSnapshot.docs.length); i++) {
                        final doc = absenceSnapshot.docs[i];
                        final data = doc.data() as Map<String, dynamic>;
                        print('Dokumen ${i+1} (${doc.id}):');
                        data.forEach((key, value) {
                          print('  $key: $value (${value.runtimeType})');
                        });
                      }
                      
                      // 6. AMBIL DATA USERS DAN EVENTS UNTUK NAMA LENGKAP
                      final Set<String> userIds = {};
                      final Set<String> eventIds = {};
                      
                      for (var doc in absenceSnapshot.docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        final eventId = data['event_id']?.toString() ?? '';
                        final userId = data['user_id']?.toString() ?? '';
                        
                        if (eventId.isNotEmpty) eventIds.add(eventId);
                        if (userId.isNotEmpty) userIds.add(userId);
                      }
                      
                      print('User IDs ditemukan: ${userIds.length}');
                      print('Event IDs ditemukan: ${eventIds.length}');
                      
                      // 7. AMBIL DATA USERS (jika ada)
                      final Map<String, Map<String, dynamic>> usersData = {};
                      if (userIds.isNotEmpty) {
                        print('Mengambil data users...');
                        try {
                          // Batasi maksimal 10 user per query (Firestore limit)
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
                          print('Berhasil ambil ${usersData.length} user data');
                        } catch (e) {
                          print('Gagal ambil users batch: $e');
                          // Coba satu per satu
                          for (var userId in userIds) {
                            try {
                              final userDoc = await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(userId)
                                  .get();
                              if (userDoc.exists) {
                                usersData[userId] = userDoc.data() as Map<String, dynamic>;
                              }
                            } catch (e) {
                              print('Gagal ambil user $userId: $e');
                            }
                          }
                        }
                      }
                      
                      // 8. AMBIL DATA EVENTS (jika ada)
                      final Map<String, Map<String, dynamic>> eventsData = {};
                      if (eventIds.isNotEmpty) {
                        print('Mengambil data events...');
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
                          print('Berhasil ambil ${eventsData.length} event data');
                        } catch (e) {
                          print('Gagal ambil events batch: $e');
                          // Coba satu per satu
                          for (var eventId in eventIds) {
                            try {
                              final eventDoc = await FirebaseFirestore.instance
                                  .collection('events')
                                  .doc(eventId)
                                  .get();
                              if (eventDoc.exists) {
                                eventsData[eventId] = eventDoc.data() as Map<String, dynamic>;
                              }
                            } catch (e) {
                              print('Gagal ambil event $eventId: $e');
                            }
                          }
                        }
                      }
                      
                      // 9. BUAT FILE EXCEL
                      print('Membuat file Excel...');
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
                      
                      // 10. PROSES SETIAP DATA
                      int processedCount = 0;
                      int errorCount = 0;
                      
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
                          
                          // Parse waktu absensi
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
                          final status = data['status']?.toString() ?? 'unknown';
                          
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
                          print('Error processing doc ${doc.id}: $e');
                          errorCount++;
                          
                          // Tambahkan baris error
                          sheet.appendRow([
                            doc.id,
                            'ERROR',
                            'Error processing',
                            '-',
                            'ERROR',
                            'Error processing',
                            '-',
                            'error',
                            '-',
                          ]);
                        }
                      }
                      
                      print('Diproses: $processedCount, Error: $errorCount');
                      
                      // 11. SIMPAN FILE
                      final excelBytes = excel.save();
                      if (excelBytes == null) {
                        throw Exception('Gagal membuat file Excel');
                      }
                      
                      // 12. SIMPAN SESUAI PLATFORM
                      Navigator.pop(dialogContext);
                      
                      if (uio.Platform.isAndroid || uio.Platform.isIOS) {
                        // MOBILE
                        final directory = await getTemporaryDirectory();
                        final fileName = 'riwayat_absensi_${DateTime.now().millisecondsSinceEpoch}.xlsx';
                        final filePath = '${directory.path}/$fileName';
                        
                        final file = File(filePath);
                        await file.writeAsBytes(excelBytes);
                        await OpenFilex.open(filePath);
                        
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(' $processedCount data berhasil diekspor',
                                    style: TextStyle(fontFamily: 'Poppins')),
                                if (errorCount > 0)
                                  Text('$errorCount data error',
                                      style: TextStyle(fontSize: 12, color: Colors.yellow)),
                                Text('File tersimpan di: $filePath',
                                    style: TextStyle(fontSize: 10)),
                              ],
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                        
                      } else {
                        // WEB / DESKTOP
                        final base64 = base64Encode(excelBytes);
                        final uri = 'data:application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;base64,$base64';
                        final anchor = html.AnchorElement(href: uri)
                          ..setAttribute('download', 'riwayat_absensi_${DateTime.now().millisecondsSinceEpoch}.xlsx')
                          ..click();
                        
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(' $processedCount data berhasil diekspor',
                                    style: TextStyle(fontFamily: 'Poppins')),
                                if (errorCount > 0)
                                  Text('$errorCount data error',
                                      style: TextStyle(fontSize: 12, color: Colors.yellow)),
                                const Text('File sedang didownload...',
                                    style: TextStyle(fontSize: 12)),
                              ],
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                      
                    } catch (e) {
                      Navigator.pop(dialogContext);
                      
                      print('ERROR AKHIR: $e');
                      
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Gagal mengekspor',
                                      style: TextStyle(fontFamily: 'Poppins')),
                              Text('Error: ${e.toString().substring(0, 100)}',
                                  style: const TextStyle(fontSize: 12)),
                              const Text('Cek console untuk detail',
                                  style: TextStyle(fontSize: 10)),
                            ],
                          ),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 5),
                        ),
                      );
                    }
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