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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const AlertDialog(
        content: Row(
          children: [CircularProgressIndicator(), SizedBox(width: 20), Text('Exporting data...')],
        ),
      ),
    );

    try {
      final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        Navigator.pop(context);
        _showSnackBar(context, 'User not logged in');
        return;
      }

      // Fetch absences
      final absenceSnapshot = await FirebaseFirestore.instance
          .collection('absences')
          .orderBy('absence_time', descending: true)
          .get();

      if (absenceSnapshot.docs.isEmpty) {
        Navigator.pop(context);
        _showSnackBar(context, 'No attendance data to export');
        return;
      }

      // Fetch related user and event data
      final usersData = await _fetchUsersData(absenceSnapshot);
      final eventsData = await _fetchEventsData(absenceSnapshot);

      // Create Excel
      final excel = excel_package.Excel.createExcel();
      final sheet = excel['Attendance Data'];

      // Headers
      sheet.appendRow(['No', 'Nama', 'NIM', 'Email', 'Event', 'Lokasi', 'Status', 'Waktu Absen']);

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
      _showSnackBar(context, 'File saved to: $filePath', duration: const Duration(seconds: 3));
    } catch (e) {
      Navigator.pop(context);
      debugPrint('Error exporting data: $e');
      _showSnackBar(context, 'Error: $e', backgroundColor: Colors.red);
    }
  }

  static Future<Map<String, Map<String, dynamic>>> _fetchUsersData(
    QuerySnapshot absenceSnapshot,
  ) async {
    final userIds = absenceSnapshot.docs.map((doc) => doc['user_id'] as String).toSet();
    final usersData = <String, Map<String, dynamic>>{};

    for (var userId in userIds) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (userDoc.exists) {
        usersData[userId] = userDoc.data() ?? {};
      }
    }

    return usersData;
  }

  static Future<Map<String, Map<String, dynamic>>> _fetchEventsData(
    QuerySnapshot absenceSnapshot,
  ) async {
    final eventIds = absenceSnapshot.docs.map((doc) => doc['event_id'] as String).toSet();
    final eventsData = <String, Map<String, dynamic>>{};

    for (var eventId in eventIds) {
      final eventDoc = await FirebaseFirestore.instance.collection('events').doc(eventId).get();
      if (eventDoc.exists) {
        eventsData[eventId] = eventDoc.data() ?? {};
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor, duration: duration),
    );
  }
}
