class EventRegisterLogic {
  Map<String, dynamic> validateRegister({required String eventId, required String userId}) {
    if (eventId.isEmpty || userId.isEmpty) {
      return {'success': false, 'message': 'Event ID atau User ID tidak boleh kosong'};
    }

    return {'success': true, 'message': 'Valid untuk pendaftaran'};
  }
}
