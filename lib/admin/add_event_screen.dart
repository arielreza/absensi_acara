import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddEventScreen extends StatefulWidget {
  const AddEventScreen({super.key});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final name = TextEditingController();
  final description = TextEditingController();
  final location = TextEditingController();
  final organizer = TextEditingController();
  DateTime? selectedDate;

  Future<void> saveEvent() async {
    if (name.text.isEmpty || selectedDate == null) return;

    await FirebaseFirestore.instance.collection("events").add({
      "event_name": name.text,
      "description": description.text,
      "event_date": Timestamp.fromDate(selectedDate!),
      "location": location.text,
      "organizer": organizer.text,
      "is_active": true,
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Event"),
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
                  initialDate: DateTime.now(),
                );

                if (date != null) {
                  setState(() {
                    selectedDate = date;
                  });
                }
              },
              child: Text(
                selectedDate == null
                    ? "Pilih Tanggal"
                    : "Tanggal: ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: saveEvent,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              child: const Text("Save Event"),
            ),
          ],
        ),
      ),
    );
  }
}
