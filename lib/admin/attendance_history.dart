import 'package:flutter/material.dart';
import '../models/attendance.dart';
import '../services/database_service.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  late Future<List<Attendance>> _attendanceFuture;

  @override
  void initState() {
    super.initState();
    _attendanceFuture = DatabaseService().getAttendanceHistory();
  }

  void _refreshData() {
    setState(() {
      _attendanceFuture = DatabaseService().getAttendanceHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Presensi'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: FutureBuilder<List<Attendance>>(
        future: _attendanceFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final attendanceList = snapshot.data ?? [];

          if (attendanceList.isEmpty) {
            return const Center(
              child: Text('Belum ada data presensi'),
            );
          }

          return ListView.builder(
            itemCount: attendanceList.length,
            itemBuilder: (context, index) {
              final attendance = attendanceList[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Text(
                      attendance.participantName[0],
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    attendance.participantName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Event: ${attendance.event}'),
                      Text(
                        'Waktu: ${_formatTime(attendance.attendanceTime)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: Chip(
                    label: Text(attendance.status),
                    backgroundColor: attendance.status == 'Hadir' 
                        ? Colors.green 
                        : Colors.orange,
                    labelStyle: const TextStyle(color: Colors.white),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.day}/${time.month}/${time.year} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}