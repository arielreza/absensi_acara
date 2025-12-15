import 'package:absensi_acara/admin/service/scanner_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:absensi_acara/admin/admin_home.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ScannerService _scannerService = ScannerService();
  final MobileScannerController cameraController = MobileScannerController();

  bool _isProcessing = false;
  String? _lastScannedCode;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  // ================= PROCESS QR =================
  Future<void> _processQrCode(String qrData) async {
    if (_isProcessing || _lastScannedCode == qrData) return;

    _lastScannedCode = qrData;
    setState(() => _isProcessing = true);

    try {
      final absenceId = qrData.trim();

      if (absenceId.isEmpty) {
        _showResultDialog(false, 'QR Code tidak valid');
        return;
      }

      final result = await _scannerService.scanAndUpdateAttendance(absenceId);

      _showResultDialog(
        result['success'],
        result['message'],
        data: result['data'],
      );
    } catch (e) {
      _showResultDialog(false, 'Terjadi kesalahan:\n$e');
    } finally {
      setState(() => _isProcessing = false);
      Future.delayed(const Duration(seconds: 2), () {
        _lastScannedCode = null;
      });
    }
  }

  // ================= RESULT DIALOG =================
  void _showResultDialog(
    bool success,
    String message, {
    Map<String, dynamic>? data,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: success ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(success ? 'Berhasil' : 'Gagal'),
          ],
        ),
        content: Text(message),
        actions: [
          if (!success)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _isProcessing = false;
                  _lastScannedCode = null;
                });
              },
              child: const Text('SCAN ULANG'),
            ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              if (success) {
                await _exitScanner();
              }
            },
            child: const Text('SELESAI'),
          ),
        ],
      ),
    );
  }

  // ================= EXIT SCANNER =================
  Future<void> _exitScanner() async {
    try {
      await cameraController.stop();
    } catch (_) {}

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
      (route) => false,
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _exitScanner,
        ),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: cameraController.torchState,
              builder: (_, state, __) {
                return Icon(
                  state == TorchState.on ? Icons.flash_on : Icons.flash_off,
                );
              },
            ),
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              for (final barcode in capture.barcodes) {
                if (barcode.rawValue != null && !_isProcessing) {
                  _processQrCode(barcode.rawValue!);
                  break;
                }
              }
            },
          ),

          // ===== OVERLAY =====
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
