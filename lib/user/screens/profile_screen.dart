import 'package:absensi_acara/services/auth_service.dart';
import 'package:absensi_acara/user/widgets/profile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: context.read<AuthService>().getUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data;

        if (data == null) {
          return const Center(child: Text("Gagal memuat profil"));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.blue,
                child: const Icon(Icons.person, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 16),
              Text(
                data['email'] ?? context.read<AuthService>().currentUser?.email ?? 'User',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              ProfileInfoCard(
                title: "Nama Lengkap",
                value: data["name"] ?? "-",
                icon: Icons.person,
              ),
              const SizedBox(height: 12),
              ProfileInfoCard(title: "NIM", value: data["nim"] ?? "-", icon: Icons.badge),
              const SizedBox(height: 12),
              ProfileInfoCard(title: 'Email', value: data['email'] ?? '-', icon: Icons.email),
              const SizedBox(height: 12),
              ProfileInfoCard(title: 'Status', value: 'Aktif', icon: Icons.check_circle),
            ],
          ),
        );
      },
    );
  }
}
