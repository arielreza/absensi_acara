import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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
    final doc = await FirebaseFirestore.instance
        .collection("events")
        .doc(widget.eventId)
        .get();

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

    await FirebaseFirestore.instance
        .collection("events")
        .doc(widget.eventId)
        .update({
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
    await FirebaseFirestore.instance
        .collection("events")
        .doc(widget.eventId)
        .delete();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Edit Event',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          const SizedBox(height: 24),
          
          // Event Name Field
          _buildInputField(
            label: 'Event Name',
            controller: nameC,
          ),
          const SizedBox(height: 15),
          
          // Description Field
          _buildInputField(
            label: 'Description',
            controller: descC,
            maxLines: 1,
          ),
          const SizedBox(height: 15),
          
          // Location Field
          _buildInputField(
            label: 'Location',
            controller: locationC,
          ),
          const SizedBox(height: 15),
          
          // Organizer Field
          _buildInputField(
            label: 'Organizer',
            controller: organizerC,
          ),
          const SizedBox(height: 15),
          
          // Participants Quota Field
          _buildInputField(
            label: 'Participants Quota',
            controller: quotaC,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 15),
          
          // Participants Count Field
          _buildInputField(
            label: 'Participants Count',
            controller: participantsC,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 15),
          
          // Date Field
          _buildDateField(),
          
          const SizedBox(height: 35),
          
          // Active Event Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Active Event',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Show Event in Home',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: isActive,
                  onChanged: (v) => setState(() => isActive = v),
                  activeColor: const Color(0xFF594AFC),
                  inactiveThumbColor: Colors.grey[400],
                  inactiveTrackColor: Colors.grey[300],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 40),
          
          // Update Button
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF594AFC),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 9.5,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: updateEvent,
                child: const Center(
                  child: Text(
                    'Update Event',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 18),
          
          // Delete Button
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: const Color(0xFF9A2824),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 9.5,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Event'),
                      content: const Text('Are you sure you want to delete this event?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            deleteEvent();
                          },
                          child: const Text(
                            'Delete',
                            style: TextStyle(color: Color(0xFF9A2824)),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                child: const Center(
                  child: Text(
                    'Delete Event',
                    style: TextStyle(
                      color: Color(0xFF9A2824),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFFCACACA),
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date',
          style: TextStyle(
            color: Colors.black,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 5),
        InkWell(
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
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFCACACA),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Text(
                  DateFormat('dd MMMM yyyy').format(selectedDate!),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Color(0xFF594AFC),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}