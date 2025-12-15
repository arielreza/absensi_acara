import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:absensi_acara/user/service/event_register_service.dart';
import 'package:absensi_acara/user/screens/success_screen.dart';

class ReviewTicketScreen extends ConsumerStatefulWidget {
  final String eventId;
  final String userId;

  const ReviewTicketScreen({
    super.key,
    required this.eventId,
    required this.userId,
  });

  @override
  ConsumerState<ReviewTicketScreen> createState() => _ReviewTicketScreenState();
}

class _ReviewTicketScreenState extends ConsumerState<ReviewTicketScreen> {
  bool _isSubmitting = false;

  Future<List<DocumentSnapshot>> _fetchData() async {
    final eventDoc = await FirebaseFirestore.instance
        .collection('events')
        .doc(widget.eventId)
        .get();
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();
    return [eventDoc, userDoc];
  }

  Future<void> _onContinue() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(eventRegisterService)
          .daftarEvent(eventId: widget.eventId, userId: widget.userId);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SuccessScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mendaftar: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Ticket Summary'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<DocumentSnapshot>>(
        future: _fetchData(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (snap.hasError || snap.data == null)
            return const Center(child: Text('Gagal mengambil data'));

          final eventDoc = snap.data![0];
          final userDoc = snap.data![1];

          final event = eventDoc.data() as Map<String, dynamic>? ?? {};
          final user = userDoc.data() as Map<String, dynamic>? ?? {};

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey[200],
                            ),
                            child:
                                event['image_url'] != null &&
                                    (event['image_url'] as String).isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      event['image_url'],
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Icon(
                                    Icons.event,
                                    size: 34,
                                    color: Colors.grey,
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event['event_name'] ?? 'Untitled',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  event['location'] ?? '-',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // user info list
                  Expanded(
                    child: ListView(
                      children: [
                        _infoRow(
                          'Full Name',
                          user['full_name']?.toString() ??
                              user['name']?.toString() ??
                              '-',
                        ),
                        _infoRow('NIM', user['nim']?.toString() ?? '-'),
                        _infoRow('Major', user['major']?.toString() ?? '-'),
                        _infoRow(
                          'Phone Number',
                          user['phone']?.toString() ?? '-',
                        ),
                        _infoRow('Email', user['email']?.toString() ?? '-'),
                      ],
                    ),
                  ),

                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12, top: 8),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _onContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF594AFC),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Continue'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
