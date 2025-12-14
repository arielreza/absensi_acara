import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'fake_scanner_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Responsiveness Test - QR processing time', (tester) async {
    final fakeService = FakeScannerService();

    final start = DateTime.now();

    final result = await fakeService.scanAndUpdateAttendance('QR_TEST_123');

    final end = DateTime.now();
    final duration = end.difference(start);

    debugPrint('Responsivity Test Time: ${duration.inMilliseconds} ms');

    expect(result['success'], true);
    expect(duration.inMilliseconds < 2000, true);
  });
}
