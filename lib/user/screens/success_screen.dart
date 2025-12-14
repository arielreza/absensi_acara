import 'package:absensi_acara/user/screens/user_screen.dart';
import 'package:flutter/material.dart';

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Back Button
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, size: 22),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              const SizedBox(height: 40),

              // Success Badge Image
              Image.asset(
                'assets/images/success.png', // perbaikan path
                width: 120,
                height: 120,
              ),

              const SizedBox(height: 30),

              // Title
              const Text(
                'Congratulations!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
              ),

              const SizedBox(height: 10),

              // Subtitle
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'You have successfully Booked Event Ticket.\nYou can see your Ticket now',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.4),
                ),
              ),

              const SizedBox(height: 80),

              // Button: View My Ticket
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const UserHomeScreen(initialTab: 1), // tab 2 = history
                        ),
                        (route) => false,
                      );
                    },
                    child: const Text(
                      'View My Ticket',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Go to Home Link
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UserHomeScreen()),
                  );
                },
                child: const Text(
                  'Go to Home',
                  style: TextStyle(
                    color: Color(0xFF6C63FF),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
