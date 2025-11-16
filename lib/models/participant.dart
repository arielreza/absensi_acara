class Participant {
  final String id;
  final String name;
  final String event;
  final String email;
  final String phone;

  Participant({
    required this.id,
    required this.name,
    required this.event,
    required this.email,
    required this.phone,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'event': event,
      'email': email,
      'phone': phone,
    };
  }

  factory Participant.fromMap(Map<String, dynamic> map) {
    return Participant(
      id: map['id'],
      name: map['name'],
      event: map['event'],
      email: map['email'],
      phone: map['phone'],
    );
  }
}