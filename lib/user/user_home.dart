import 'package:absensi_acara/user/service/event_register_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
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
    final nim = context.read<AuthService>().currentUser?.email ?? '';

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
                const Text('Halo,', style: TextStyle(color: Colors.white70, fontSize: 14)),
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
          StreamBuilder(
            stream: FirebaseFirestore.instance.collection('events').snapshots(),
            builder: (context, asyncSnapshot) {
              if (asyncSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!asyncSnapshot.hasData || asyncSnapshot.data!.docs.isEmpty) {
                return const Center(child: Text("Tidak ada event"));
              }

              final events = asyncSnapshot.data!.docs;

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final doc = events[index];
                  final data = doc.data();

                  if (data['is_active'] == true) {
                    return _EventCard(
                      eventId: doc.id,
                      title: data['event_name'] ?? '',
                      date: data['event_date'],
                      location: data['location'] ?? '',
                      nim: nim,
                    );
                  }
                  return const SizedBox.shrink();
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // ---------------- EVENT TAB ---------------- //
  Widget _buildEventTab() {
    final nim = context.read<AuthService>().currentUser?.email ?? '';

    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('events').snapshots(),
      builder: (context, asyncSnapshot) {
        if (asyncSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!asyncSnapshot.hasData || asyncSnapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Tidak ada event"));
        }

        final events = asyncSnapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final doc = events[index];
            final data = doc.data();

            if (data['is_active'] == true) {
              return _EventCard(
                eventId: doc.id,
                title: data['event_name'],
                date: data['event_date'],
                location: data['location'],
                nim: nim,
              );
            }
            return null;
          },
        );
      },
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
              child: const Icon(Icons.person, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              user?.email ?? 'User',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text('Peserta', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            _ProfileInfoCard(title: 'Email', value: user?.email ?? '-', icon: Icons.email),
            const SizedBox(height: 12),
            _ProfileInfoCard(title: 'Role', value: 'Peserta', icon: Icons.badge),
            const SizedBox(height: 12),
            _ProfileInfoCard(title: 'Status', value: 'Aktif', icon: Icons.check_circle),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final String count;
  final IconData icon;

  const _StatusBadge({required this.label, required this.count, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          count,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}

class _EventCard extends ConsumerWidget {
  final String eventId;
  final String title;
  final Timestamp date;
  final String location;
  final String nim;
  // final String imageUrl;

  const _EventCard({
    required this.eventId,
    required this.title,
    required this.date,
    required this.location,
    required this.nim,
    // required this.imageUrl,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventDate = date.toDate();
    final dateFormatted = DateFormat("EEE, dd MMM yyyy").format(eventDate);
    final timeFormatted = DateFormat("HH:mm").format(eventDate);
    final statusColor = Colors.green;
    final bgColor = Colors.green.shade50;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---------------------- IMAGE ----------------------
          SizedBox(height: 160),

          // ClipRRect(
          //   borderRadius: const BorderRadius.only(
          //     topLeft: Radius.circular(16),
          //     topRight: Radius.circular(16),
          //   ),
          //   child: Image.network(imageUrl, height: 160, width: double.infinity, fit: BoxFit.cover),
          // ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---------------------- TITLE ----------------------
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),

                const SizedBox(height: 8),

                // ---------------------- DATE + TIME ----------------------
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      "$dateFormatted   •   $timeFormatted",
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // ---------------------- LOCATION ----------------------
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        location,
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ---------------------- FREE LABEL ----------------------
                InkWell(
                  onTap: () async {
                    ref.read(eventRegisterService).daftarEvent(eventId: eventId, nimPeserta: nim);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Daftar',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}

// class _EventCard extends ConsumerWidget {
//   final String eventId;
//   final String title;
//   final Timestamp date;
//   final String location;
//   // final String type;
//   // final String status;
//   final String nim;

//   const _EventCard({
//     super.key,
//     required this.eventId,
//     required this.title,
//     required this.date,
//     required this.location,
//     // required this.type,
//     // required this.status,
//     required this.nim,
//   });

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final dateTime = date.toDate(); // convert dari Timestamp
//     final formattedDate = DateFormat('EEE, dd MMM yyyy • HH:mm').format(dateTime);
//     final statusColor = Colors.green;
//     final bgColor = Colors.green.shade50;

//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: bgColor,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: statusColor.withOpacity(0.3)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Expanded(
//                 child: Text(
//                   title,
//                   style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//               InkWell(
//                 onTap: () async {
//                   ref.read(eventRegisterService).daftarEvent(eventId: eventId, nimPeserta: nim);
//                 },
//                 borderRadius: BorderRadius.circular(12),
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                   decoration: BoxDecoration(
//                     color: statusColor,
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Text(
//                     'Daftar',
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 11,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           Row(
//             children: [
//               const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
//               const SizedBox(width: 6),
//               Text(formattedDate, style: const TextStyle(fontSize: 12, color: Colors.grey)),
//             ],
//           ),
//           const SizedBox(height: 4),
//           Row(
//             children: [
//               const Icon(Icons.location_on, size: 14, color: Colors.grey),
//               const SizedBox(width: 6),
//               Expanded(
//                 child: Text(
//                   location,
//                   style: const TextStyle(fontSize: 12, color: Colors.grey),
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

class _HistoryItem extends StatelessWidget {
  final String title;
  final String date;
  final String status;
  final String time;

  const _HistoryItem({
    required this.title,
    required this.date,
    required this.status,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = status == 'Hadir'
        ? Colors.green
        : status == 'Izin'
        ? Colors.orange
        : Colors.red;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(Icons.event, color: statusColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(date, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(width: 8),
                    Text(time, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileInfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _ProfileInfoCard({required this.title, required this.value, required this.icon});

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
