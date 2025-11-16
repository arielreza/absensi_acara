import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import '../models/participant.dart';
import '../models/attendance.dart';
import '../services/database_service.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  String scanResult = 'Belum ada scan';
  bool isLoading = false;

  Future<void> scanQR() async {
    setState(() {
      isLoading = true;
    });

    try {
      String barcodeScanResult = await FlutterBarcodeScanner.scanBarcode(
        '#ff6666',
        'Cancel',
        true,
        ScanMode.QR,
      );

      if (barcodeScanResult != '-1') {
        await processScanResult(barcodeScanResult);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> processScanResult(String participantId) async {
    final dbService = DatabaseService();
    
    Participant? participant = await dbService.getParticipant(participantId);
    
    if (participant != null) {
      bool alreadyAttended = await dbService.isAlreadyAttended(participantId);
      
      if (!alreadyAttended) {
        Attendance attendance = Attendance(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          participantId: participant.id,
          participantName: participant.name,
          event: participant.event,
          attendanceTime: DateTime.now(),
        );
        
        await dbService.insertAttendance(attendance);
        
        setState(() {
          scanResult = 'Berhasil: ${participant.name} - ${participant.event}';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Presensi berhasil: ${participant.name}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          scanResult = 'Peserta sudah absen: ${participant.name}';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${participant.name} sudah melakukan absensi'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else {
      setState(() {
        scanResult = 'Peserta tidak ditemukan';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID peserta tidak valid'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon dan Title Section - Centered
              Column(
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    size: 120,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Scan QR Code Peserta',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              
              const SizedBox(height: 40),
              
              // Result Section - Centered
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Status Scan:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
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
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Loading Indicator - Centered
              if (isLoading) ...[
                const Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Memindai QR Code...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
              
              // Scan Button - Centered
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : scanQR,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.qr_code_scanner, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Mulai Scan',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
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