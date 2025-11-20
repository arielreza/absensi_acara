import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart'; // WAJIB dari flutterfire
import 'services/auth_service.dart';
import 'admin/admin_home.dart';
import 'user/user_home.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase menggunakan konfigurasi flutterfire
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized.');
  } catch (e) {
    print('Firebase init error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthService(),
      child: MaterialApp(
        title: 'Aplikasi Presensi QR Code',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          primarySwatch: Colors.blue,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

/// Mengecek login + role admin/user
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;

    // Jika belum login → ke halaman login
    if (user == null) {
      return const LoginScreen();
    }

    // Jika login → cek role dari Firestore
    return FutureBuilder<String?>(
      future: auth.getUserRole(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final role = snapshot.data ?? 'user';

        // Routing berdasarkan role
        if (role == 'admin') {
          return const AdminHomeScreen();
        } else {
          return const UserHomeScreen();
        }
      },
    );
  }
}
