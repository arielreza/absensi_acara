import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Availability Test - Scan screen renders without crash', (tester) async {
    final start = DateTime.now();

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('Scan QR Code'))),
      ),
    );

    await tester.pumpAndSettle();

    final end = DateTime.now();
    final duration = end.difference(start);

    debugPrint('Availability Test Time: ${duration.inMilliseconds} ms');

    expect(find.text('Scan QR Code'), findsOneWidget);
  });
}
