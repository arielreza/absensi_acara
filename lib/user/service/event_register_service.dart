import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final eventRegisterService = Provider<EventRegisterService>((ref) {
  return EventRegisterService(FirebaseFirestore.instance);
});

class EventRegisterService {
  final FirebaseFirestore firestore;

  EventRegisterService(this.firestore);

  /// ===================== DAFTAR EVENT =====================
  Future<void> daftarEvent({
    required String eventId,
    required String userId,
  }) async {
    final eventRef = firestore.collection("events").doc(eventId);
    final absenceRef = firestore.collection("absences").doc();

    await firestore.runTransaction((transaction) async {
      final eventSnap = await transaction.get(eventRef);

      if (!eventSnap.exists) {
        throw Exception("EVENT_NOT_FOUND");
      }

      final data = eventSnap.data()!;
      final int quota = data["participants"] ?? 0;
      final int current = data["participants_count"] ?? 0;

      if (current >= quota) {
        throw Exception("EVENT_FULL");
      }

      // update quota
      transaction.update(eventRef, {"participants_count": current + 1});

      // simpan absensi
      transaction.set(absenceRef, {
        "absence_id": absenceRef.id,
        "event_id": eventId,
        "user_id": userId,
        "absence_time": null,
        "status": "belum hadir",
        "created_at": Timestamp.now(),
      });
    });
  }

  /// ===================== UNREGISTER EVENT =====================
  Future<void> unregisterEvent({
    required String eventId,
    required String userId,
    required String absenceId,
  }) async {
    final eventRef = firestore.collection("events").doc(eventId);
    final absenceRef = firestore.collection("absences").doc(absenceId);

    await firestore.runTransaction((transaction) async {
      final eventSnap = await transaction.get(eventRef);

      if (!eventSnap.exists) {
        throw Exception("EVENT_NOT_FOUND");
      }

      final data = eventSnap.data()!;
      final int current = data["participants_count"] ?? 0;

      // kurangi peserta (minimal 0)
      transaction.update(eventRef, {
        "participants_count": current > 0 ? current - 1 : 0,
      });

      // hapus absensi
      transaction.delete(absenceRef);
    });
  }
}
