import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddEventScreen extends StatefulWidget {
  const AddEventScreen({super.key});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final TextEditingController nameC = TextEditingController();
  final TextEditingController descC = TextEditingController();
  final TextEditingController locationC = TextEditingController();
  final TextEditingController organizerC = TextEditingController();
  final TextEditingController quotaC = TextEditingController();

  DateTime? selectedDate = DateTime.now();
  bool isActive = true;

  Future<void> pickDate() async {
    final DateTime? result = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (result != null) {
      setState(() {
        selectedDate = result;
      });
    }
  }

  Future<void> saveEvent() async {
    if (nameC.text.isEmpty ||
        descC.text.isEmpty ||
        locationC.text.isEmpty ||
        organizerC.text.isEmpty ||
        quotaC.text.isEmpty ||
        selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Harap lengkapi semua data")),
      );
      return;
    }

    int quota = int.tryParse(quotaC.text.trim()) ?? 0;

    await FirebaseFirestore.instance.collection("events").add({
      "event_name": nameC.text,
      "description": descC.text,
      "location": locationC.text,
      "organizer": organizerC.text,
      "participants": quota,            // ✔ sama seperti EditEventScreen
      "participants_count": 0,          // ✔ default
      "event_date": Timestamp.fromDate(selectedDate!),
      "is_active": isActive,
      "created_at": Timestamp.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Event berhasil ditambahkan!")),
    );

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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: nameC,
            decoration: const InputDecoration(labelText: "Event Name"),
          ),
          TextField(
            controller: descC,
            maxLines: 2,
            decoration: const InputDecoration(labelText: "Description"),
          ),
          TextField(
            controller: locationC,
            decoration: const InputDecoration(labelText: "Location"),
          ),
          TextField(
            controller: organizerC,
            decoration: const InputDecoration(labelText: "Organizer"),
          ),
          TextField(
            controller: quotaC,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Participants Quota"),
          ),

          const SizedBox(height: 16),

          ListTile(
            title: Text(
              selectedDate == null
                  ? "Pick Event Date"
                  : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
            ),
            trailing: const Icon(Icons.calendar_month),
            onTap: pickDate,
          ),

          SwitchListTile(
            title: const Text("Active Event"),
            subtitle: const Text("Jika aktif, event akan tampil di dashboard"),
            value: isActive,
            onChanged: (v) => setState(() => isActive = v),
          ),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: saveEvent,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text("Save Event"),
          ),
        ],
      ),
    );
  }
}
