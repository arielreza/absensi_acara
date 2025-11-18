import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'admin/admin_home.dart';
import 'user/user_home.dart';
import 'services/database_service.dart';
import 'services/auth_service.dart';
import 'models/participant.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print('Firebase init error: $e');
  }

  // Initialize local database in background (non-blocking)
  _initializeSampleData();
  
  runApp(const MyApp());
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
    return ChangeNotifierProvider(
      create: (_) => AuthService(),
      child: MaterialApp(
        title: 'Aplikasi Presensi QR Code',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

/// Routes to LoginScreen, UserHomeScreen or AdminHomeScreen based on user auth state & role
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    
    if (user != null) {
      // Check user role and route accordingly
      return FutureBuilder<String?>(
        future: context.read<AuthService>().getUserRole(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          final role = snapshot.data ?? 'user';
          
          if (role == 'admin') {
            return const AdminHomeScreen();
          } else {
            return const UserHomeScreen();
          }
        },
      );
    }
    return const LoginScreen();
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