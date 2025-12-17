// lib/admin/utils/export_helper.dart
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart' as excel_package;
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class ExportHelper {
  static Future<void> exportAttendanceData(BuildContext context) async {
    try {
      final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _showSnackBar(context, 'User not logged in');
        return;
      }

      // TAMPILKAN DIALOG DENGAN DROPDOWN
      final selectedEventId = await _showEventSelectionDialogWithDropdown(context);
      
      // Jika user membatalkan atau tidak memilih event
      if (selectedEventId == null) {
        return;
      }

      // Jika memilih "All Events", gunakan null untuk meng-export semua data
      String? eventFilterId = selectedEventId == 'all' ? null : selectedEventId;

      // Tampilkan loading dialog
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => WillPopScope(
            onWillPop: () async => false,
            child: const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20), 
                  Text('Exporting data...')
                ],
              ),
            ),
          ),
        );
      }

      // Fetch data dengan handling index error
      List<QueryDocumentSnapshot<Map<String, dynamic>>> absenceDocs = [];
      
      try {
        if (eventFilterId != null) {
          // Coba dengan orderBy dulu (jika index sudah dibuat)
          try {
            final snapshot = await FirebaseFirestore.instance
                .collection('absences')
                .where('event_id', isEqualTo: eventFilterId)
                .orderBy('absence_time', descending: true)
                .get();
            absenceDocs = snapshot.docs;
          } catch (e) {
            // Jika error karena index, ambil tanpa orderBy
            debugPrint('Index error, fetching without orderBy: $e');
            final snapshot = await FirebaseFirestore.instance
                .collection('absences')
                .where('event_id', isEqualTo: eventFilterId)
                .get();
            absenceDocs = snapshot.docs;
            
            // Sort manual berdasarkan waktu (descending)
            absenceDocs.sort((a, b) {
              final dataA = a.data();
              final dataB = b.data();
              final timeA = dataA['absence_time'] as Timestamp?;
              final timeB = dataB['absence_time'] as Timestamp?;
              
              if (timeA == null && timeB == null) return 0;
              if (timeA == null) return 1;
              if (timeB == null) return -1;
              
              return timeB.compareTo(timeA); // Descending
            });
          }
        } else {
          // Untuk "All Events", pakai orderBy seperti biasa
          final snapshot = await FirebaseFirestore.instance
              .collection('absences')
              .orderBy('absence_time', descending: true)
              .get();
          absenceDocs = snapshot.docs;
        }
      } catch (e) {
        debugPrint('Error fetching absences: $e');
        if (context.mounted) {
          Navigator.pop(context);
          _showSnackBar(context, 'Error fetching data: $e', backgroundColor: Colors.red);
        }
        return;
      }

      if (absenceDocs.isEmpty) {
        if (context.mounted) {
          Navigator.pop(context);
          _showSnackBar(context, 'No attendance data to export');
        }
        return;
      }

      // Fetch related user and event data
      final usersData = await _fetchUsersData(absenceDocs);
      
      // AMBIL NAMA EVENT UNTUK TITLE FILE
      String eventName = 'All Events';
      if (eventFilterId != null) {
        final eventDoc = await FirebaseFirestore.instance
            .collection('events')
            .doc(eventFilterId)
            .get();
        if (eventDoc.exists) {
          final eventData = eventDoc.data();
          eventName = eventData?['event_name']?.toString() ?? 'Selected Event';
        }
      }
      final eventsData = await _fetchEventsData(absenceDocs);

      // Create Excel
      final excel = excel_package.Excel.createExcel();
      
      // GUNAKAN NAMA EVENT UNTUK NAMA SHEET
      final sheet = excel['Attendance Data - $eventName'] ?? excel['Attendance Data'];

      // Headers
      sheet.appendRow(['No', 'Nama', 'NIM', 'Email', 'Event', 'Lokasi', 'Status', 'Waktu Absen']);

      // Data rows
      int no = 1;
      for (var doc in absenceDocs) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final userId = data['user_id']?.toString() ?? '';
        final eventId = data['event_id']?.toString() ?? '';
        final status = data['status']?.toString() ?? '';
        final absenceTime = data['absence_time'] as Timestamp?;

        final userData = usersData[userId];
        final userName = userData?['name']?.toString() ?? 'Unknown';
        final userNim = userData?['nim']?.toString() ?? '-';
        final userEmail = userData?['email']?.toString() ?? '-';
        
        final eventData = eventsData[eventId];
        final eventNameFromData = eventData?['event_name']?.toString() ?? 'Unknown Event';
        final eventLocation = eventData?['location']?.toString() ?? '-';

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
          eventNameFromData,
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
      
      // GUNAKAN NAMA EVENT UNTUK NAMA FILE
      final cleanEventName = eventName.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
      final fileName = 'attendance_data_${cleanEventName}_$timestamp.xlsx';
      final filePath = '${targetDir.path}/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(excelBytes);

      // Open file
      await OpenFilex.open(filePath);

      if (context.mounted) {
        Navigator.pop(context);
      }
      
      // TAMPILKAN EVENT NAME DALAM NOTIFIKASI
      if (context.mounted) {
        _showSnackBar(
          context, 
          'Data for "$eventName" exported successfully!\nSaved to: $filePath', 
          duration: const Duration(seconds: 4)
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        debugPrint('Error exporting data: $e');
        _showSnackBar(context, 'Error: $e', backgroundColor: Colors.red);
      }
    }
  }

  // FUNGSI UNTUK MENAMPILKAN DIALOG DENGAN DROPDOWN
  static Future<String?> _showEventSelectionDialogWithDropdown(BuildContext context) async {
    // Ambil data events terlebih dahulu
    final eventsSnapshot = await FirebaseFirestore.instance
        .collection('events')
        .where('is_active', isEqualTo: true)
        .get();

    final events = eventsSnapshot.docs;
    List<Map<String, dynamic>> eventList = [];
    
    // Tambahkan opsi "All Events" di awal
    eventList.add({
      'id': 'all',
      'name': 'All Events',
      'description': 'Export all attendance data',
      'date': '',
      'location': ''
    });
    
    // Tambahkan events dari Firestore
    for (var event in events) {
      final eventData = event.data() as Map<String, dynamic>? ?? {};
      final eventName = eventData['event_name']?.toString() ?? 'Unnamed Event';
      final eventDate = eventData['event_date'] as Timestamp?;
      final location = eventData['location']?.toString() ?? '-';
      
      String dateStr = '-';
      if (eventDate != null) {
        final dt = eventDate.toDate();
        dateStr = '${dt.day}/${dt.month}/${dt.year}';
      }
      
      eventList.add({
        'id': event.id,
        'name': eventName,
        'description': '$dateStr • $location',
        'date': dateStr,
        'location': location
      });
    }

    String? selectedEventId = 'all'; // Default value
    final formKey = GlobalKey<FormState>();

    return await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                'Select Event to Export',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              content: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                width: double.maxFinite,
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Choose an event to export attendance data:',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        
                        // DROPDOWN dengan menuProps untuk membatasi tinggi dropdown
                        DropdownButtonFormField<String>(
                          value: selectedEventId,
                          decoration: InputDecoration(
                            labelText: 'Event',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          ),
                          items: eventList.map((event) {
                            return DropdownMenuItem<String>(
                              value: event['id'] as String,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    event['name'] as String,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if ((event['description'] as String).isNotEmpty)
                                    Text(
                                      event['description'] as String,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedEventId = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select an event';
                            }
                            return null;
                          },
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down),
                          elevation: 2,
                          menuMaxHeight: MediaQuery.of(context).size.height * 0.3,
                          dropdownColor: Colors.white,
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // TAMPILKAN INFO EVENT YANG DIPILIH
                        if (selectedEventId != null && selectedEventId != 'all')
                          FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                            future: FirebaseFirestore.instance
                                .collection('events')
                                .doc(selectedEventId)
                                .get(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const SizedBox(
                                  height: 50,
                                  child: Center(
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  ),
                                );
                              }
                              
                              if (snapshot.hasData && snapshot.data!.exists) {
                                final eventData = snapshot.data!.data();
                                final participants = eventData?['participants'] ?? 0;
                                final participantsCount = eventData?['participants_count'] ?? 0;
                                
                                return Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.blue[100]!),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Event Info:',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Participants: $participantsCount/$participants',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              return const SizedBox();
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      Navigator.pop(context, selectedEventId);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Export',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static Future<Map<String, Map<String, dynamic>>> _fetchUsersData(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> absenceDocs,
  ) async {
    final Set<String> userIds = {};
    
    for (var doc in absenceDocs) {
      final data = doc.data();
      final userId = data['user_id']?.toString();
      if (userId != null && userId.isNotEmpty) {
        userIds.add(userId);
      }
    }
    
    final usersData = <String, Map<String, dynamic>>{};

    for (var userId in userIds) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (userDoc.exists) {
        usersData[userId] = userDoc.data() as Map<String, dynamic>? ?? {};
      }
    }

    return usersData;
  }

  static Future<Map<String, Map<String, dynamic>>> _fetchEventsData(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> absenceDocs,
  ) async {
    final Set<String> eventIds = {};
    
    for (var doc in absenceDocs) {
      final data = doc.data();
      final eventId = data['event_id']?.toString();
      if (eventId != null && eventId.isNotEmpty) {
        eventIds.add(eventId);
      }
    }
    
    final eventsData = <String, Map<String, dynamic>>{};

    for (var eventId in eventIds) {
      final eventDoc = await FirebaseFirestore.instance.collection('events').doc(eventId).get();
      if (eventDoc.exists) {
        eventsData[eventId] = eventDoc.data() as Map<String, dynamic>? ?? {};
      }
    }

    return eventsData;
  }

  static void _showSnackBar(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 2),
  }) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message), 
          backgroundColor: backgroundColor, 
          duration: duration
        ),
      );
    }
  }
}