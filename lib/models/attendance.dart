class Attendance {
  final String id;
  final String participantId;
  final String participantName;
  final String event;
  final DateTime attendanceTime;
  final String status;

  Attendance({
    required this.id,
    required this.participantId,
    required this.participantName,
    required this.event,
    required this.attendanceTime,
    this.status = 'Hadir',
  });

/*************  ✨ Windsurf Command ⭐  *************/
  /// Returns a map representation of the [Attendance] object.
  ///
  /// The returned map contains the following keys:
  ///
  /// - 'id': the unique identifier of the attendance.
  /// - 'participantId': the unique identifier of the participant.
  /// - 'participantName': the name of the participant.
  /// - 'event': the name of the event.
  /// - 'attendanceTime': the timestamp of the attendance in ISO 8601 format.
  /// - 'status': the status of the attendance (either 'Hadir' or 'Tidak Hadir').
/*******  8386dc28-fd3b-4618-894b-9d3ea78f2714  *******/
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participantId': participantId,
      'participantName': participantName,
      'event': event,
      'attendanceTime': attendanceTime.toIso8601String(),
      'status': status,
    };
  }

  factory Attendance.fromMap(Map<String, dynamic> map) {
    return Attendance(
      id: map['id'],
      participantId: map['participantId'],
      participantName: map['participantName'],
      event: map['event'],
      attendanceTime: DateTime.parse(map['attendanceTime']),
      status: map['status'],
    );
  }
}