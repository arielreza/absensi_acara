// lib/screens/qr_scanner_screen.dart
import 'package:absensi_acara/admin/service/scanner_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ScannerService _scannerService = ScannerService();
  MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;
  String? _lastScannedCode;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  Future<void> _processQrCode(String qrData) async {
    if (_isProcessing || _lastScannedCode == qrData) return;

    _lastScannedCode = qrData;

    setState(() {
      _isProcessing = true;
    });

    try {
      debugPrint('═══════════════════════════════════');
      debugPrint('Scanned Absence ID: $qrData');

      // Validasi absence_id (pastikan bukan string kosong)
      final absenceId = qrData.trim();

      if (absenceId.isEmpty) {
        _showResultDialog(
          success: false,
          message: 'QR Code tidak valid atau kosong',
        );
        return;
      }

      // Proses attendance menggunakan absence_id
      debugPrint('Processing attendance for absence_id: $absenceId');
      final result = await _scannerService.scanAndUpdateAttendance(absenceId);

      debugPrint('Result: $result');
      debugPrint('═══════════════════════════════════');

      _showResultDialog(
        success: result['success'],
        message: result['message'],
        data: result['data'],
      );
    } catch (e, stackTrace) {
      debugPrint('Error: $e');
      debugPrint('Stack Trace: $stackTrace');
      _showResultDialog(success: false, message: 'Terjadi kesalahan:\n\n$e');
    } finally {
      setState(() {
        _isProcessing = false;
      });

      // Reset setelah 2 detik
      Future.delayed(const Duration(seconds: 2), () {
        _lastScannedCode = null;
      });
    }
  }

  void _showResultDialog({
    required bool success,
    required String message,
    Map<String, dynamic>? data,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: success ? Colors.green : Colors.red,
              size: 30,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                success ? 'Berhasil' : 'Gagal',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message, style: const TextStyle(fontSize: 16)),
              if (data != null) ...[
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                _buildInfoRow('User ID', data['user_id']?.toString() ?? '-'),
                _buildInfoRow('Event ID', data['event_id']?.toString() ?? '-'),
                _buildInfoRow('Status', data['status']?.toString() ?? '-'),
                if (data['attendance_time'] != null)
                  _buildInfoRow(
                    'Waktu Absen',
                    _formatTimestamp(data['attendance_time']),
                  ),
              ],
            ],
          ),
        ),
        actions: [
          if (!success)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _isProcessing = false;
                  _lastScannedCode = null;
                });
              },
              child: const Text('SCAN ULANG'),
            ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (success) {
                Navigator.of(context).pop(); // Kembali ke screen sebelumnya
              } else {
                setState(() {
                  _isProcessing = false;
                  _lastScannedCode = null;
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: success ? Colors.green : Colors.grey,
            ),
            child: Text(success ? 'SELESAI' : 'TUTUP'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const Text(': ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '-';

    try {
      if (timestamp is Timestamp) {
        final dateTime = timestamp.toDate();
        return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      }
      return timestamp.toString();
    } catch (e) {
      return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        title: const Text('Scan QR Code'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: cameraController.torchState,
              builder: (context, state, child) {
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
          // Camera
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null && !_isProcessing) {
                  _processQrCode(barcode.rawValue!);
                  break;
                }
              }
            },
          ),

          // Overlay gelap dengan lubang
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.6),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    height: 250,
                    width: 250,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Border putih
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  // Corner decorations
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.greenAccent, width: 4),
                          left: BorderSide(color: Colors.greenAccent, width: 4),
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.greenAccent, width: 4),
                          right: BorderSide(
                            color: Colors.greenAccent,
                            width: 4,
                          ),
                        ),
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.greenAccent,
                            width: 4,
                          ),
                          left: BorderSide(color: Colors.greenAccent, width: 4),
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.greenAccent,
                            width: 4,
                          ),
                          right: BorderSide(
                            color: Colors.greenAccent,
                            width: 4,
                          ),
                        ),
                        borderRadius: BorderRadius.only(
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Instruksi
          Positioned(
            bottom: 80,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.qr_code_scanner, color: Colors.white, size: 40),
                  SizedBox(height: 8),
                  Text(
                    'Arahkan kamera ke QR Code',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Pastikan QR Code terlihat jelas',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),

          // Loading overlay
          if (_isProcessing)
            Container(
              color: Colors.black87,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 4,
                      ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Memproses QR Code...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
// ```

// ## Struktur Collection Firestore

// Pastikan collection `absence` memiliki struktur seperti ini:
// ```
// absence/
//   - JA2NcF5f6q2L34k0giGx (document ID / absence_id)
//     - user_id: "user123"
//     - event_id: "event456"
//     - status: "terdaftar" // akan diupdate jadi "hadir"
//     - registered_at: timestamp
//     - attendance_time: null // akan diisi saat scan
//     - updated_at: timestamp
