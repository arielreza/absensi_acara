import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditEventScreen extends StatefulWidget {
  final String eventId;
  const EditEventScreen({super.key, required this.eventId});

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final TextEditingController nameC = TextEditingController();
  final TextEditingController descC = TextEditingController();
  final TextEditingController locationC = TextEditingController();
  final TextEditingController organizerC = TextEditingController();
  final TextEditingController quotaC = TextEditingController();
  final TextEditingController participantsC = TextEditingController();

  DateTime? selectedDate;
  bool isActive = false;

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadEvent();
  }

  Future<void> loadEvent() async {
    final doc =
        await FirebaseFirestore.instance.collection("events").doc(widget.eventId).get();

    final data = doc.data()!;

    nameC.text = data["event_name"] ?? "";
    descC.text = data["description"] ?? "";
    locationC.text = data["location"] ?? "";
    organizerC.text = data["organizer"] ?? "";

    quotaC.text = (data["participants"] ?? 0).toString();
    participantsC.text = (data["participants_count"] ?? 0).toString();

    Timestamp ts = data["event_date"];
    selectedDate = ts.toDate();

    isActive = data["is_active"] ?? false;

    setState(() => loading = false);
  }

  Future<void> updateEvent() async {
    if (nameC.text.isEmpty ||
        descC.text.isEmpty ||
        locationC.text.isEmpty ||
        organizerC.text.isEmpty ||
        quotaC.text.isEmpty ||
        participantsC.text.isEmpty ||
        selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Semua field harus diisi")),
      );
      return;
    }

    int quota = int.tryParse(quotaC.text.trim()) ?? 0;
    int participants = int.tryParse(participantsC.text.trim()) ?? 0;

    await FirebaseFirestore.instance.collection("events").doc(widget.eventId).update({
      "event_name": nameC.text,
      "description": descC.text,
      "location": locationC.text,
      "organizer": organizerC.text,
      "participants": quota,
      "participants_count": participants,
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
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Event"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: nameC, decoration: const InputDecoration(labelText: "Event Name")),
          TextField(controller: descC, maxLines: 2, decoration: const InputDecoration(labelText: "Description")),
          TextField(controller: locationC, decoration: const InputDecoration(labelText: "Location")),
          TextField(controller: organizerC, decoration: const InputDecoration(labelText: "Organizer")),

          // QUOTA
          TextField(
            controller: quotaC,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Participants Quota"),
          ),

          // PARTICIPANTS COUNT
          TextField(
            controller: participantsC,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Participants Count"),
          ),

          const SizedBox(height: 16),

          ListTile(
            title: Text("${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}"),
            trailing: const Icon(Icons.calendar_month),
            onTap: () async {
              final pick = await showDatePicker(
                context: context,
                initialDate: selectedDate!,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );

              if (pick != null) {
                setState(() => selectedDate = pick);
              }
            },
          ),

          SwitchListTile(
            title: const Text("Active Event"),
            subtitle: const Text("Tampilkan event di dashboard"),
            value: isActive,
            onChanged: (v) => setState(() => isActive = v),
          ),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: updateEvent,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text("Update Event"),
          ),

          const SizedBox(height: 10),

          // DELETE BUTTON
          ElevatedButton(
            onPressed: deleteEvent,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text("Delete Event"),
          ),
        ],
      ),
    );
  }
}
