import 'package:absensi_acara/models/absence.dart';
import 'package:absensi_acara/models/event.dart';
import 'package:absensi_acara/models/user.dart';
import 'package:absensi_acara/user/widgets/detail_history_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

class DetailHistoryScreen extends StatelessWidget {
  final String eventId;
  final String userId;

  const DetailHistoryScreen({super.key, required this.eventId, required this.userId});

  Stream<Map<String, dynamic>> getHistoryDatas({required String eventId, required String userId}) {
    // 1) Stream absence
    return FirebaseFirestore.instance
        .collection("absences")
        .where("event_id", isEqualTo: eventId)
        .where("user_id", isEqualTo: userId)
        .limit(1)
        .snapshots()
        .switchMap((snap) {
          if (snap.docs.isEmpty) {
            return Stream.value({"error": "absence_not_found"});
          }

          final absence = Absence.fromFirestore(snap.docs.first);

          // 2) Stream event + user
          final eventStream = FirebaseFirestore.instance
              .collection("events")
              .doc(absence.eventId)
              .snapshots()
              .map((d) {
                final event = Event.fromFirestore(d);
                return event;
              });

          final userStream = FirebaseFirestore.instance
              .collection("users")
              .doc(absence.userId)
              .snapshots()
              .map((d) {
                final user = User.fromFirestore(d);
                return user;
              });

          // 3) Gabungkan
          return Rx.combineLatest3(Stream.value(absence), eventStream, userStream, (
            absence,
            event,
            user,
          ) {
            return {"absence": absence, "event": event, "user": user};
          }).doOnError((error, stackTrace) {});
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "My Ticket",
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: getHistoryDatas(eventId: eventId, userId: userId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.containsKey("error")) {
            return const Center(child: Text("Absence not found"));
          }

          final absence = snapshot.data!["absence"] as Absence;
          final event = snapshot.data!["event"] as Event;
          final user = snapshot.data!["user"] as User;

          return DetailHistoryCard(absence: absence, event: event, user: user);
        },
      ),
    );
  }
}

class DetailColumn extends StatelessWidget {
  final String title;
  final String value;
  final bool fullWidth;

  const DetailColumn({super.key, required this.title, required this.value, this.fullWidth = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : 140,
      child: Column(
        crossAxisAlignment: fullWidth ? CrossAxisAlignment.start : CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
