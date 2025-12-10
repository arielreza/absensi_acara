// lib/services/absence_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ScannerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'absences';

  // Ambil data absence berdasarkan absence_id
  Future<DocumentSnapshot?> getAbsenceById(String absenceId) async {
    try {
      final docSnapshot = await _firestore.collection(_collectionName).doc(absenceId).get();

      if (docSnapshot.exists) {
        return docSnapshot;
      }
      return null;
    } catch (e) {
      throw Exception('Error getting absence by ID: $e');
    }
  }

  // Update status kehadiran berdasarkan absence_id
  Future<Map<String, dynamic>> scanAndUpdateAttendance(String absenceId) async {
    try {
      // Ambil document berdasarkan absence_id
      final docSnapshot = await getAbsenceById(absenceId);

      if (docSnapshot == null || !docSnapshot.exists) {
        return {'success': false, 'message': 'Data registrasi tidak ditemukan'};
      }

      final data = docSnapshot.data() as Map<String, dynamic>;
      final currentStatus = data['status'] ?? '';

      // Cek apakah sudah absen
      if (currentStatus == 'hadir') {
        return {
          'success': false,
          'message': 'Anda sudah melakukan absensi sebelumnya',
          'data': data,
        };
      }

      // Update status menjadi hadir
      await _firestore.collection(_collectionName).doc(absenceId).update({
        'status': 'hadir',
        'attendance_time': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Ambil data yang sudah diupdate
      final updatedDoc = await getAbsenceById(absenceId);
      final updatedData = updatedDoc?.data() as Map<String, dynamic>?;

      return {'success': true, 'message': 'Absensi berhasil dicatat', 'data': updatedData ?? data};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Method tambahan untuk cek status absence
  Future<Map<String, dynamic>?> getAbsenceDetails(String absenceId) async {
    try {
      final docSnapshot = await getAbsenceById(absenceId);

      if (docSnapshot == null || !docSnapshot.exists) {
        return null;
      }

      return docSnapshot.data() as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
}
