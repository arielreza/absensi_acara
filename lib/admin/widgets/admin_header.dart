// lib/admin/widgets/admin_header.dart
import 'package:flutter/material.dart';

class AdminHeader extends StatelessWidget {
  const AdminHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.person, size: 34, color: Colors.deepPurple),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "Admin Dashboard 👋",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
              ),
              SizedBox(height: 4),
              Text(
                "Manage your events and participants",
                style: TextStyle(color: Colors.black54, fontFamily: 'Poppins'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
