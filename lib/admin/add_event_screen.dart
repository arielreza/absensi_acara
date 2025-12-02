import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddEventScreen extends StatefulWidget {
  const AddEventScreen({super.key});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _organizerCtrl = TextEditingController();
  final _maxParticipantsCtrl = TextEditingController();

  DateTime? _selectedDate;

  Future<void> _saveEvent() async {
    if (_nameCtrl.text.isEmpty ||
        _descCtrl.text.isEmpty ||
        _maxParticipantsCtrl.text.isEmpty ||
        _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    await FirebaseFirestore.instance.collection("events").add({
      "event_name": _nameCtrl.text.trim(),
      "description": _descCtrl.text.trim(),
      "location": _locationCtrl.text.trim(),
      "organizer": _organizerCtrl.text.trim(),
      "event_date": Timestamp.fromDate(_selectedDate!),
      "is_active": true,
      "max_participants": int.parse(_maxParticipantsCtrl.text),
      "participants_count": 0, // default saat buat event
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Event"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: "Event Name"),
              ),
              TextField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: "Description"),
              ),
              TextField(
                controller: _locationCtrl,
                decoration: const InputDecoration(labelText: "Location"),
              ),
              TextField(
                controller: _organizerCtrl,
                decoration: const InputDecoration(labelText: "Organizer"),
              ),
              TextField(
                controller: _maxParticipantsCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Max Participants"),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
                child: Text(
                  _selectedDate == null
                      ? "Select Event Date"
                      : "Selected: ${_selectedDate!.toLocal()}".split(" ")[0],
                ),
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: _saveEvent,
                child: const Text("Save Event"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
