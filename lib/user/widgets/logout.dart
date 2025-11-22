import 'package:absensi_acara/services/auth_service.dart';
import 'package:flutter/material.dart';

void showLogoutDialog(BuildContext context, AuthService auth) {
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
