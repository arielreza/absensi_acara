import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _selectedTab = 0;

  void _showLogoutDialog(BuildContext context, AuthService auth) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              auth.signOut();
            },
            child: const Text('Ya, Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

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
            onPressed: () => _showLogoutDialog(context, auth),
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
        return _buildHomeTab();
      case 1:
        return _buildEventTab();
      case 2:
        return _buildHistoryTab();
      case 3:
        return _buildProfileTab();
      default:
        return _buildHomeTab();
    }
  }

  // ---------------- HOME TAB ---------------- //
  Widget _buildHomeTab() {
    final user = context.read<AuthService>().currentUser;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: Colors.blue,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Halo,', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ---------------- EVENT TAB ---------------- //
  Widget _buildEventTab() {
    return Center(
      child: Text("Daftar Event Akan Ditampilkan Di Sini"),
    );
  }

  // ---------------- HISTORY TAB ---------------- //
  Widget _buildHistoryTab() {
    return Center(
      child: Text("Riwayat Presensi Akan Ditampilkan Di Sini"),
    );
  }

  // ---------------- PROFILE TAB ---------------- //
  Widget _buildProfileTab() {
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
                data["name"] ?? "-",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),

              Text(
                data["email"] ?? "-",
                style: const TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 24),

              _ProfileInfoCard(
                title: "Nama Lengkap",
                value: data["name"] ?? "-",
                icon: Icons.person,
              ),
              const SizedBox(height: 12),

              _ProfileInfoCard(
                title: "NIM",
                value: data["nim"] ?? "-",
                icon: Icons.badge,
              ),
              const SizedBox(height: 12),

              _ProfileInfoCard(
                title: "Email",
                value: data["email"] ?? "-",
                icon: Icons.email,
              ),
              const SizedBox(height: 12),

              _ProfileInfoCard(
                title: "Role",
                value: data["role"] ?? "-",
                icon: Icons.verified_user,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ================= WIDGET KECIL ================= //

class _ProfileInfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _ProfileInfoCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
