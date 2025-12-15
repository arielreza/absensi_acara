// lib/admin/widgets/quick_actions_section.dart
import 'package:flutter/material.dart';

import '../attendance_history.dart';
import '../event_management_screen.dart';
import '../participant_management_screen.dart';
import '../scan_screen.dart';
import '../utils/export_helper.dart';

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Quick Actions",
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 115,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _QuickActionTile(
                icon: Icons.qr_code_scanner,
                label: "Scan QR",
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanScreen()));
                },
              ),
              _QuickActionTile(
                icon: Icons.people_alt,
                label: "Participant\nManagement",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ParticipantManagementScreen()),
                  );
                },
              ),
              _QuickActionTile(
                icon: Icons.event,
                label: "Event\nManagement",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EventManagementScreen()),
                  );
                },
              ),
              _QuickActionTile(
                icon: Icons.insert_drive_file,
                label: "Attendance\nReport",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AttendanceHistoryScreen()),
                  );
                },
              ),
              _QuickActionTile(
                icon: Icons.upload_file,
                label: "Export\nData",
                onTap: () {
                  ExportHelper.exportAttendanceData(context);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.deepPurple.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.deepPurple.shade100),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: Colors.deepPurple),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                  color: Colors.deepPurple,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
