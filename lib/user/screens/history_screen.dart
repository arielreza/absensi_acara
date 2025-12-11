import 'package:absensi_acara/services/auth_service.dart';
import 'package:absensi_acara/user/service/get_event_history.dart';
import 'package:absensi_acara/user/widgets/history_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = context.read<AuthService>();
    final userId = auth.currentUser!.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("absences")
          .where("user_id", isEqualTo: userId)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return Center(child: CircularProgressIndicator());

        final absences = snap.data!.docs;
        return Scaffold(
          backgroundColor: const Color(0xFFFBFBFB),
          appBar: AppBar(
            backgroundColor: const Color(0xFFFBFBFB),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
              onPressed: () {
                // Navigator.push(context, MaterialPageRoute(builder: (_) => his))
              },
            ),
            title: const Text(
              "History",
              style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w600),
            ),
            centerTitle: true,
          ),

          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("absences")
                .where("user_id", isEqualTo: userId)
                .snapshots(),
            builder: (context, snap) {
              final absences = snap.data!.docs;
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: absences.length,
                itemBuilder: (context, index) {
                  final eventId = absences[index]['event_id'];

                  final eventHistory = ref.watch(
                    getEventHistory({"eventId": eventId, "userId": userId}),
                  );

                  return eventHistory.when(
                    loading: () => const CircularProgressIndicator(),
                    error: (e, s) => Text("Error: $e"),
                    data: (data) {
                      if (data["error"] != null) {
                        return const Text("Absence not found");
                      }

                      final event = data["event"];
                      return HistoryCard(
                        title: event.name,
                        date: DateFormat("MMMM dd yyyy").format((event.date).toDate()),
                        time: DateFormat("h.mm a – h.mm a").format((event.date).toDate()),
                        location: event.location,
                        eventId: event.id,
                        userId: userId,
                        // participants: "127 Participant",
                      );
                    },
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
