import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final eventRegisterService = Provider<EventRegisterService>((ref) {
  return EventRegisterService(FirebaseFirestore.instance);
});

class EventRegisterService {
  final FirebaseFirestore firestore;

  EventRegisterService(this.firestore);

  Future<void> daftarEvent({required String eventId, required String userId}) async {
    final docRef = firestore.collection("absences").doc();

    await docRef.set({
      "absence_id": docRef.id,
      "event_id": eventId,
      "user_id": userId,
      "absence_time": null,
      "status": "belum hadir",
    });
  }
}
