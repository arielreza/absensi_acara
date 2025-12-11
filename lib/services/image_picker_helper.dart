// lib/services/image_picker_helper.dart

import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';

class ImagePickerHelper {
  static final ImagePicker _picker = ImagePicker();
  
  /// Pilih gambar dari galeri
  static Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,  // Batasi resolusi untuk hemat bandwidth
        maxHeight: 1080,
        imageQuality: 85, // Kompresi kualitas (0-100)
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('❌ Error picking image: $e');
      return null;
    }
  }
  
  /// Pilih gambar dari kamera
  static Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('❌ Error taking photo: $e');
      return null;
    }
  }
  
  /// Show dialog untuk pilih sumber gambar
  static Future<File?> showImageSourceDialog(BuildContext context) async {
    return showModalBottomSheet<File?>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF594AFC)),
                title: const Text('Pilih dari Galeri', style: TextStyle(fontFamily: 'Poppins')),
                onTap: () async {
                  Navigator.pop(context); // Tutup bottom sheet
                  final file = await pickImageFromGallery();
                  if (context.mounted && file != null) {
                    // Return file via callback atau Navigator
                    Navigator.pop(context, file);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF594AFC)),
                title: const Text('Ambil Foto', style: TextStyle(fontFamily: 'Poppins')),
                onTap: () async {
                  Navigator.pop(context); // Tutup bottom sheet
                  final file = await pickImageFromCamera();
                  if (context.mounted && file != null) {
                    Navigator.pop(context, file);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.close, color: Colors.grey),
                title: const Text('Batal', style: TextStyle(fontFamily: 'Poppins')),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }
}