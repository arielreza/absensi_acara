import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'fake_scanner_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Security Test - Empty QR Code rejected', (tester) async {
    final fakeService = FakeScannerService();

    final start = DateTime.now();

    final result = await fakeService.scanAndUpdateAttendance('');

    final end = DateTime.now();
    final duration = end.difference(start);

    debugPrint('Security Test Time: ${duration.inMilliseconds} ms');

    expect(result['success'], false);
  });
}
