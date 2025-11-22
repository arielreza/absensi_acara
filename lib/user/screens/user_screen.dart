import 'package:absensi_acara/services/auth_service.dart';
import 'package:absensi_acara/user/screens/event_screen.dart';
import 'package:absensi_acara/user/screens/history_screen.dart';
import 'package:absensi_acara/user/screens/home_screen.dart';
import 'package:absensi_acara/user/screens/profile_screen.dart';
import 'package:absensi_acara/user/widgets/logout.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        title: const Text('Aplikasi Presensi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => showLogoutDialog(context, auth),
          ),
        ],
      ),
      body: _buildTabContent(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Event'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        onTap: (index) {
          setState(() => _selectedTab = index);
        },
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return HomeScreen();
      case 1:
        return EventScreen();
      case 2:
        return HistoryScreen();
      case 3:
        return ProfileScreen();
      default:
        return HomeScreen();
    }
  }
}
