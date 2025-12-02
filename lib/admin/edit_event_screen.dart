import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditEventScreen extends StatefulWidget {
  final String eventId;
  const EditEventScreen({super.key, required this.eventId});

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _organizerCtrl = TextEditingController();
  final _maxParticipantsCtrl = TextEditingController();
  final _participantsCountCtrl = TextEditingController();

  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadEventData();
  }

  Future<void> _loadEventData() async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection("events")
        .doc(widget.eventId)
        .get();

    var data = doc.data() as Map<String, dynamic>;

    _nameCtrl.text = data["event_name"];
    _descCtrl.text = data["description"];
    _locationCtrl.text = data["location"];
    _organizerCtrl.text = data["organizer"];
    _maxParticipantsCtrl.text = data["max_participants"].toString();
    _participantsCountCtrl.text = data["participants_count"].toString();
    _selectedDate = (data["event_date"] as Timestamp).toDate();

    setState(() {});
  }

  Future<void> _updateEvent() async {
    await FirebaseFirestore.instance.collection("events").doc(widget.eventId).update({
      "event_name": _nameCtrl.text,
      "description": _descCtrl.text,
      "location": _locationCtrl.text,
      "organizer": _organizerCtrl.text,
      "event_date": Timestamp.fromDate(_selectedDate!),
      "max_participants": int.parse(_maxParticipantsCtrl.text),
      "participants_count": int.parse(_participantsCountCtrl.text),
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Event")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: "Event Name")),
              TextField(controller: _descCtrl, decoration: const InputDecoration(labelText: "Description")),
              TextField(controller: _locationCtrl, decoration: const InputDecoration(labelText: "Location")),
              TextField(controller: _organizerCtrl, decoration: const InputDecoration(labelText: "Organizer")),
              TextField(controller: _maxParticipantsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Max Participants")),
              TextField(controller: _participantsCountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Participants Count")),
              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? DateTime.now(),
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
                onPressed: _updateEvent,
                child: const Text("Update Event"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
