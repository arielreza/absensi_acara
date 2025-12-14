import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final eventRegisterService = Provider<EventRegisterService>((ref) {
  return EventRegisterService(FirebaseFirestore.instance);
});

class EventRegisterService {
  final FirebaseFirestore firestore;

  EventRegisterService(this.firestore);

  Future<void> daftarEvent({
    required String eventId,
    required String userId,
  }) async {
    final eventRef = firestore.collection("events").doc(eventId);

    await firestore.runTransaction((transaction) async {
      final eventSnap = await transaction.get(eventRef);

      if (!eventSnap.exists) {
        throw Exception("EVENT_NOT_FOUND");
      }

      final data = eventSnap.data()!;

      final int quota = data["participants"] ?? 0;
      final int current = data["participants_count"] ?? 0;

      // 🚫 EVENT FULL
      if (current >= quota) {
        throw Exception("EVENT_FULL");
      }

      // 🚫 CEK SUDAH TERDAFTAR
      final alreadyRegistered = await firestore
          .collection("absences")
          .where("event_id", isEqualTo: eventId)
          .where("user_id", isEqualTo: userId)
          .limit(1)
          .get();

      if (alreadyRegistered.docs.isNotEmpty) {
        throw Exception("ALREADY_REGISTERED");
      }

      // ✅ UPDATE COUNT
      transaction.update(eventRef, {"participants_count": current + 1});

      // ✅ SIMPAN ABSENCE
      final absenceRef = firestore.collection("absences").doc();
      transaction.set(absenceRef, {
        "absence_id": absenceRef.id,
        "event_id": eventId,
        "user_id": userId,
        "status": "belum hadir",
        "absence_time": null,
        "created_at": FieldValue.serverTimestamp(),
      });
    });
  }
}
