import 'package:absensi_acara/user/widgets/history_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBFBFB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () {},
        ),
        title: const Text(
          "History",
          style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),

      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('events').snapshots(),
        builder: (context, asyncSnapshot) {
          if (asyncSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!asyncSnapshot.hasData || asyncSnapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Kamu belum daftar event apapun"));
          }

          final events = asyncSnapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final doc = events[index];
              final data = doc.data();
              return HistoryCard(
                title: data['event_name'],
                date: DateFormat("MMMM dd yyyy").format((data['event_date'] as Timestamp).toDate()),
                time: DateFormat(
                  "h.mm a – h.mm a",
                ).format((data['event_date'] as Timestamp).toDate()),
                location: data['location'],
                // participants: "127 Participant",
              );
            },
          );
        },
      ),
    );
  }
}
