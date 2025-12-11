// lib/services/cloudinary_service.dart

import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CloudinaryService {
  static const String cloudName = 'dcgiaruab';
  static const String uploadPreset = 'event_upload';  // gunakan preset unsigned

  static Future<Map<String, dynamic>> uploadImage(File imageFile) async {
    try {
      if (!imageFile.existsSync()) {
        throw Exception('File tidak ditemukan');
      }

      print('📤 Preparing upload...');
      print('📁 File: ${imageFile.path}');
      print('📏 Size: ${await imageFile.length()} bytes');

      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );

      final request = http.MultipartRequest('POST', url);

      // 🟢 ADD FILE
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      // 🟢 ADD UPLOAD PRESET (WAJIB)
      request.fields['upload_preset'] = uploadPreset;

      // ⚠️ JANGAN kirim folder lagi karena preset sudah punya "Asset folder: events"
      // request.fields['folder'] = 'events';  // ❌ HAPUS INI

      print('🔄 Uploading to Cloudinary...');
      print('🌐 Cloud Name: $cloudName');
      print('📋 Upload Preset: $uploadPreset');

      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);

      print('📡 Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseString);

        print('✅ Upload successful!');
        print('🖼️ URL: ${jsonResponse['secure_url']}');
        print('🆔 Public ID: ${jsonResponse['public_id']}');

        return {
          'secure_url': jsonResponse['secure_url'],
          'public_id': jsonResponse['public_id'],
        };
      } else {
        print('❌ Upload failed: ${response.statusCode}');
        print('📄 Response: $responseString');

        try {
          final errorJson = json.decode(responseString);
          throw Exception(errorJson['error']['message']);
        } catch (_) {
          throw Exception('Upload failed: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('❌ Error uploading to Cloudinary: $e');
      rethrow;
    }
  }
}
