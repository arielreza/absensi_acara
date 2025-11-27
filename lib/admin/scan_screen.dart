import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  String scanResult = 'Belum ada scan';
  bool isLoading = false;
  MobileScannerController cameraController = MobileScannerController();

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  // void _onBarcodeDetected(BarcodeCapture capture) {
  //   final List<Barcode> barcodes = capture.barcodes;

  //   if (barcodes.isNotEmpty) {
  //     final String barcode = barcodes.first.rawValue ?? '';

  //     if (barcode.isNotEmpty) {
  //       processScanResult(barcode);
  //     }
  //   }
  // }

  // Future<void> processScanResult(String participantId) async {
  //   if (isLoading) return;

  //   setState(() {
  //     isLoading = true;
  //   });

  //   try {
  //     final dbService = DatabaseService();
  //     User? participant = await dbService.getParticipant(participantId);

  //     if (participant != null) {
  //       bool alreadyAttended = await dbService.isAlreadyAttended(participantId);

  //       if (!alreadyAttended) {
  //         Attendance attendance = Attendance(
  //           id: DateTime.now().millisecondsSinceEpoch.toString(),
  //           participantId: participant.id,
  //           participantName: participant.name,
  //           // event: participant.event,
  //           attendanceTime: DateTime.now(),
  //         );

  //         await dbService.insertAttendance(attendance);

  //         setState(() {
  //           scanResult = 'Berhasil: ${participant.name} - ${participant.event}';
  //         });

  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(
  //             content: Text('Presensi berhasil: ${participant.name}'),
  //             backgroundColor: Colors.green,
  //             duration: const Duration(seconds: 2),
  //           ),
  //         );
  //       } else {
  //         setState(() {
  //           scanResult = 'Peserta sudah absen: ${participant.name}';
  //         });

  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(
  //             content: Text('${participant.name} sudah melakukan absensi'),
  //             backgroundColor: Colors.orange,
  //             duration: const Duration(seconds: 2),
  //           ),
  //         );
  //       }
  //     } else {
  //       setState(() {
  //         scanResult = 'Peserta tidak ditemukan';
  //       });

  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text('ID peserta tidak valid'),
  //           backgroundColor: Colors.red,
  //           duration: Duration(seconds: 2),
  //         ),
  //       );
  //     }
  //   } catch (e) {
  //     setState(() {
  //       scanResult = 'Error: $e';
  //     });

  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
  //   } finally {
  //     setState(() {
  //       isLoading = false;
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: cameraController.torchState,
              builder: (context, state, child) {
                switch (state) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                }
              },
            ),
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: cameraController.cameraFacingState,
              builder: (context, state, child) {
                switch (state) {
                  case CameraFacing.front:
                    return const Icon(Icons.camera_front);
                  case CameraFacing.back:
                    return const Icon(Icons.camera_rear);
                }
              },
            ),
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Camera Preview
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                // MobileScanner(controller: cameraController, onDetect: _onBarcodeDetected),
                // Scanner overlay
                CustomPaint(painter: ScannerOverlay()),
              ],
            ),
          ),

          // Result Section
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Status:', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Text(
                    scanResult,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: _getStatusColor(scanResult),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (isLoading)
                    const Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 8),
                        Text('Memproses...'),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String result) {
    if (result.startsWith('Berhasil')) {
      return Colors.green;
    } else if (result.startsWith('Peserta sudah')) {
      return Colors.orange;
    } else if (result.startsWith('Peserta tidak')) {
      return Colors.red;
    } else {
      return Colors.black;
    }
  }
}

// Scanner Overlay untuk visual yang lebih baik
class ScannerOverlay extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;

    final path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final scanArea = size.width * 0.7;

    final scannerPath = Path()
      ..addRect(Rect.fromCircle(center: Offset(centerX, centerY), radius: scanArea / 2));

    final scanPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    path.addPath(scannerPath, Offset.zero);
    path.fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
    canvas.drawPath(scannerPath, scanPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
