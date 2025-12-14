import 'package:absensi_acara/services/auth_service.dart';
import 'package:absensi_acara/user/widgets/logout.dart';
import 'package:absensi_acara/user/widgets/profile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();

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
              const SizedBox(height: 42),
              Image.asset('assets/images/profile.png', width: 100, height: 100),
              const SizedBox(height: 16),
              Text(
                data['name'] ?? context.read<AuthService>().currentUser?.email ?? 'User',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              ProfileInfoCard(title: "Nama Lengkap", value: data["name"] ?? "-"),
              const SizedBox(height: 12),
              ProfileInfoCard(title: "NIM", value: data["nim"] ?? "-"),
              const SizedBox(height: 12),
              ProfileInfoCard(title: 'Email', value: data['email'] ?? '-'),
              const SizedBox(height: 12),
              ProfileInfoCard(title: 'Status', value: 'Aktif'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => showLogoutDialog(context, auth),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C4AFF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Log out",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
