import 'package:flutter/material.dart';
import 'admin/admin_home.dart';
import 'services/database_service.dart';
import 'models/participant.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize database and add sample data
    await _initializeSampleData();
    runApp(const MyApp());
  } catch (e) {
    print('Error during initialization: $e');
    runApp(const ErrorApp());
  }
}

Future<void> _initializeSampleData() async {
  try {
    final dbService = DatabaseService();
    
    // Sample participants
    final sampleParticipants = [
      Participant(
        id: '001',
        name: 'Ahmad Rizki',
        event: 'Seminar Flutter 2024',
        email: 'ahmad@email.com',
        phone: '081234567890',
      ),
      Participant(
        id: '002', 
        name: 'Siti Nurhaliza',
        event: 'Workshop Mobile Development',
        email: 'siti@email.com',
        phone: '081234567891',
      ),
      Participant(
        id: '003',
        name: 'Budi Santoso',
        event: 'Tech Conference 2024',
        email: 'budi@email.com',
        phone: '081234567892',
      ),
    ];

    // Insert sample data
    for (var participant in sampleParticipants) {
      await dbService.insertParticipant(participant);
    }
    print('Sample data initialized successfully');
  } catch (e) {
    print('Error initializing sample data: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplikasi Presensi QR Code',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const AdminHomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Error loading app'),
        ),
      ),
    );
  }
}