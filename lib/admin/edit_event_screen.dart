import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditEventScreen extends StatefulWidget {
  final String eventId;

  const EditEventScreen({super.key, required this.eventId});

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final name = TextEditingController();
  final description = TextEditingController();
  final location = TextEditingController();
  final organizer = TextEditingController();
  bool isActive = true;
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    loadEvent();
  }

  Future<void> loadEvent() async {
    final doc = await FirebaseFirestore.instance
        .collection("events")
        .doc(widget.eventId)
        .get();

    final data = doc.data();
    if (data != null) {
      name.text = data["event_name"] ?? "";
      description.text = data["description"] ?? "";
      location.text = data["location"] ?? "";
      organizer.text = data["organizer"] ?? "";
      isActive = data["is_active"] ?? true;

      selectedDate = (data["event_date"] as Timestamp).toDate();

      setState(() {});
    }
  }

  Future<void> updateEvent() async {
    await FirebaseFirestore.instance.collection("events").doc(widget.eventId).update({
      "event_name": name.text,
      "description": description.text,
      "location": location.text,
      "organizer": organizer.text,
      "event_date": Timestamp.fromDate(selectedDate!),
      "is_active": isActive,
    });

    Navigator.pop(context);
  }

  Future<void> deleteEvent() async {
    await FirebaseFirestore.instance.collection("events").doc(widget.eventId).delete();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (selectedDate == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Event"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: "Event Name")),
            TextField(controller: description, decoration: const InputDecoration(labelText: "Description")),
            TextField(controller: location, decoration: const InputDecoration(labelText: "Location")),
            TextField(controller: organizer, decoration: const InputDecoration(labelText: "Organizer")),

            const SizedBox(height: 12),
            TextButton(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2035),
                  initialDate: selectedDate,
                );
                if (date != null) {
                  setState(() => selectedDate = date);
                }
              },
              child: Text("Tanggal: ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}"),
            ),

            SwitchListTile(
              value: isActive,
              title: const Text("Event Aktif"),
              onChanged: (v) => setState(() => isActive = v),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: updateEvent,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              child: const Text("Update Event"),
            ),

            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: deleteEvent,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text("Delete Event"),
            ),
          ],
        ),
      ),
    );
  }
}
