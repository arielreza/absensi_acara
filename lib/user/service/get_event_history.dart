import 'package:absensi_acara/models/absence.dart';
import 'package:absensi_acara/models/event.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';

import '../../models/user.dart';

final getEventHistory = StreamProvider.family<Map<String, dynamic>, Map<String, String>>((
  ref,
  params,
) {
  final eventId = params["eventId"]!;
  final userId = params["userId"]!;

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

        final eventStream = FirebaseFirestore.instance
            .collection("events")
            .doc(absence.eventId)
            .snapshots()
            .map(Event.fromFirestore);

        final userStream = FirebaseFirestore.instance
            .collection("users")
            .doc(absence.userId)
            .snapshots()
            .map(User.fromFirestore);

        return Rx.combineLatest3(Stream.value(absence), eventStream, userStream, (
          absence,
          event,
          user,
        ) {
          return {"absence": absence, "event": event, "user": user};
        });
      });
});
