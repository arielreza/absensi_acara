import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ✅ Tambahkan .autoDispose
final getEventHistory = FutureProvider.autoDispose
    .family<Map<String, dynamic>, Map<String, String>>((ref, params) async {
      final eventId = params["eventId"];
      final userId = params["userId"];

      print("Fetching event: $eventId"); // Debug log (hanya sekali per event)

      try {
        if (eventId == null || eventId.isEmpty) {
          return {"error": "Event ID is null or empty"};
        }

        final eventDoc = await FirebaseFirestore.instance.collection("events").doc(eventId).get();

        if (!eventDoc.exists) {
          return {"error": "Event not found with ID: $eventId"};
        }

        final eventData = eventDoc.data();
        if (eventData == null) {
          return {"error": "Event data is null"};
        }

        // Parse event data
        final event = {
          "id": eventDoc.id,
          "name": eventData['event_name'] ?? 'Unnamed Event',
          "date": eventData['event_date'] ?? Timestamp.now(),
          "location": eventData['location'] ?? 'Unknown Location',
        };

        return {"event": event, "error": null};
      } catch (e) {
        print("Error in getEventHistory: $e");
        return {"error": e.toString()};
      }
    });
