// lib/widgets/admin_bottom_nav.dart
import 'package:absensi_acara/admin/admin_home.dart';
import 'package:absensi_acara/admin/event_management_screen.dart';
import 'package:absensi_acara/admin/scan_screen.dart';
import 'package:flutter/material.dart';

class AdminBottomNav extends StatelessWidget {
  final int currentIndex;

  const AdminBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      selectedItemColor: Colors.deepPurple,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.event), label: "Event"),
        BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: "Scan"),
      ],
      onTap: (index) {
        // Jangan navigate jika sudah di halaman yang sama
        if (index == currentIndex) return;

        Widget destination;
        switch (index) {
          case 0:
            destination = const AdminHomeScreen();
            break;
          case 1:
            destination = const EventManagementScreen();
            break;
          case 2:
            destination = const ScanScreen();
            break;
          default:
            return;
        }

        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => destination));
      },
    );
  }
}
