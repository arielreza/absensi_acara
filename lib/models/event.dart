class Event {
  final String id;
  final String name;
  final String description;
  final DateTime date;
  final String location;
  final int maxParticipants;

  Event({
    required this.id,
    required this.name,
    required this.description,
    required this.date,
    required this.location,
    required this.maxParticipants,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'date': date.toIso8601String(),
      'location': location,
      'maxParticipants': maxParticipants,
    };
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      date: DateTime.parse(map['date']),
      location: map['location'],
      maxParticipants: map['maxParticipants'],
    );
  }
}