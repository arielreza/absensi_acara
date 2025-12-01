import 'package:flutter/material.dart';
import 'add_event_screen.dart';
import 'edit_event_screen.dart';

class AdminEventsScreen extends StatelessWidget {
  const AdminEventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Event Management"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEventScreen()),
          );
        },
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _eventTile(
            title: "Sustainability Program",
            date: "12 Jan 2025",
            participants: "127/150",
            onEdit: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const EditEventScreen(eventId: "event123"),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _eventTile({
    required String title,
    required String date,
    required String participants,
    required VoidCallback onEdit,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(date),
          const SizedBox(height: 6),
          Text("Peserta: $participants"),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: onEdit,
              child: const Text("Edit"),
            ),
          ),
        ],
      ),
    );
  }
}
