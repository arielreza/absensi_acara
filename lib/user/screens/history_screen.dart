import 'package:absensi_acara/services/auth_service.dart';
import 'package:absensi_acara/user/widgets/history_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  // ✅ Cache untuk menyimpan event data
  final Map<String, Map<String, dynamic>> _eventCache = {};

  Future<Map<String, dynamic>> _fetchEvent(String eventId) async {
    // Check cache dulu
    if (_eventCache.containsKey(eventId)) {
      print("Using cached event: $eventId");
      return _eventCache[eventId]!;
    }

    // Fetch dari Firestore jika belum ada di cache
    print("Fetching event from Firestore: $eventId");

    try {
      final eventDoc = await FirebaseFirestore.instance.collection("events").doc(eventId).get();
      print(eventDoc.data());
      if (!eventDoc.exists) {
        return {"error": "Event not found"};
      }

      final eventData = eventDoc.data();
      if (eventData == null) {
        return {"error": "Event data is null"};
      }

      final event = {
        "id": eventDoc.id,
        "name": eventData['event_name'] ?? 'Unnamed Event',
        "date": eventData['event_date'] ?? Timestamp.now(),
        "location": eventData['location'] ?? 'Unknown Location',
      };

      // Simpan ke cache
      _eventCache[eventId] = {"event": event, "error": null};

      return _eventCache[eventId]!;
    } catch (e) {
      print("Error fetching event: $e");
      return {"error": e.toString()};
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final userId = auth.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBFBFB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
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
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No attendance history found",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final absences = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: absences.length,
            itemBuilder: (context, index) {
              final absence = absences[index];
              final eventId = absence['event_id'] as String?;

              if (eventId == null || eventId.isEmpty) {
                return const Padding(padding: EdgeInsets.all(8.0), child: Text("Invalid event ID"));
              }

              // ✅ Gunakan FutureBuilder dengan cache function
              return FutureBuilder<Map<String, dynamic>>(
                future: _fetchEvent(eventId),
                builder: (context, eventSnapshot) {
                  if (eventSnapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (eventSnapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Card(
                        color: Colors.red.shade50,
                        child: ListTile(
                          leading: const Icon(Icons.error, color: Colors.red),
                          title: const Text("Failed to load event"),
                          subtitle: Text("Error: ${eventSnapshot.error}"),
                        ),
                      ),
                    );
                  }

                  final data = eventSnapshot.data;
                  if (data == null || data["error"] != null) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Card(
                        color: Colors.orange.shade50,
                        child: ListTile(
                          leading: const Icon(Icons.warning, color: Colors.orange),
                          title: const Text("Event not found"),
                          subtitle: Text(data?["error"] ?? "Unknown error"),
                        ),
                      ),
                    );
                  }

                  final event = data["event"] as Map<String, dynamic>;

                  // Format date
                  String formattedDate = "Date not available";
                  String formattedTime = "Time not available";

                  final eventDate = event['date'];
                  if (eventDate != null && eventDate is Timestamp) {
                    try {
                      final dateTime = eventDate.toDate();
                      formattedDate = DateFormat("MMMM dd, yyyy").format(dateTime);
                      formattedTime = DateFormat("h:mm a").format(dateTime);
                    } catch (e) {
                      print("Error formatting date: $e");
                    }
                  }

                  return HistoryCard(
                    title: event['name']?.toString() ?? 'Unnamed Event',
                    date: formattedDate,
                    time: formattedTime,
                    location: event['location']?.toString() ?? 'Unknown Location',
                    eventId: event['id']?.toString() ?? '',
                    userId: userId,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
