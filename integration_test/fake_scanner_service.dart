import 'dart:async';

class FakeScannerService {
  Future<Map<String, dynamic>> scanAndUpdateAttendance(String absenceId) async {
    // Simulasi delay jaringan
    await Future.delayed(const Duration(milliseconds: 800));

    if (absenceId.isEmpty) {
      return {'success': false, 'message': 'QR Code tidak valid'};
    }

    return {
      'success': true,
      'message': 'Absensi berhasil',
      'data': {
        'user_id': 'USER_TEST',
        'event_id': 'EVENT_TEST',
        'status': 'hadir',
        'attendance_time': DateTime.now().toIso8601String(),
      },
    };
  }
}
