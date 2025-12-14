// lib/admin/add_event_screen.dart

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/cloudinary_service.dart';

class AddEventScreen extends StatefulWidget {
  const AddEventScreen({super.key});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final TextEditingController nameC = TextEditingController();
  final TextEditingController descC = TextEditingController();
  final TextEditingController locationC = TextEditingController();
  final TextEditingController organizerC = TextEditingController();
  final TextEditingController quotaC = TextEditingController();

  DateTime? selectedDate = DateTime.now();
  bool isActive = true;

  // IMAGE STATE
  File? selectedImage;
  bool isUploadingImage = false;

  Future<void> pickDate() async {
    final DateTime? result = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (result != null) {
      setState(() {
        selectedDate = result;
      });
    }
  }

  // FUNGSI PILIH GAMBAR
  Future<void> pickImage() async {
    print('🔍 Opening image picker...'); // Debug

    final result = await showModalBottomSheet<File?>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext bottomSheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF594AFC)),
                title: const Text('Pilih dari Galeri', style: TextStyle(fontFamily: 'Poppins')),
                onTap: () async {
                  Navigator.pop(bottomSheetContext); // Tutup bottom sheet dulu

                  final XFile? image = await ImagePicker().pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 1920,
                    maxHeight: 1080,
                    imageQuality: 85,
                  );

                  if (image != null && mounted) {
                    final file = File(image.path);
                    print('✅ Image selected: ${image.path}');
                    setState(() {
                      selectedImage = file;
                    });
                  } else {
                    print('❌ No image selected from gallery');
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF594AFC)),
                title: const Text('Ambil Foto', style: TextStyle(fontFamily: 'Poppins')),
                onTap: () async {
                  Navigator.pop(bottomSheetContext);

                  final XFile? image = await ImagePicker().pickImage(
                    source: ImageSource.camera,
                    maxWidth: 1920,
                    maxHeight: 1080,
                    imageQuality: 85,
                  );

                  if (image != null && mounted) {
                    final file = File(image.path);
                    print('✅ Photo taken: ${image.path}');
                    setState(() {
                      selectedImage = file;
                    });
                  } else {
                    print('❌ No photo taken');
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.close, color: Colors.grey),
                title: const Text('Batal', style: TextStyle(fontFamily: 'Poppins')),
                onTap: () => Navigator.pop(bottomSheetContext),
              ),
            ],
          ),
        );
      },
    );
  }

  // FUNGSI SAVE EVENT + UPLOAD IMAGE
  Future<void> saveEvent() async {
    // Validasi input
    if (nameC.text.isEmpty ||
        descC.text.isEmpty ||
        locationC.text.isEmpty ||
        organizerC.text.isEmpty ||
        quotaC.text.isEmpty ||
        selectedDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Harap lengkapi semua data")));
      return;
    }

    setState(() {
      isUploadingImage = true;
    });

    try {
      String imageUrl = '';
      String imagePublicId = '';

      // Upload gambar ke Cloudinary jika ada
      if (selectedImage != null) {
        final uploadResult = await CloudinaryService.uploadImage(selectedImage!);
        imageUrl = uploadResult['secure_url'];
        imagePublicId = uploadResult['public_id'];
      }

      int quota = int.tryParse(quotaC.text.trim()) ?? 0;

      // Simpan ke Firestore
      await FirebaseFirestore.instance.collection("events").add({
        "event_name": nameC.text,
        "description": descC.text,
        "location": locationC.text,
        "organizer": organizerC.text,
        "participants": quota,
        "participants_count": 0,
        "event_date": Timestamp.fromDate(selectedDate!),
        "is_active": isActive,
        "image_url": imageUrl, // URL gambar dari Cloudinary
        "image_public_id": imagePublicId, // Public ID untuk referensi
        "created_at": Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Event berhasil ditambahkan!"), backgroundColor: Colors.green),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      setState(() {
        isUploadingImage = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Add Event',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          const SizedBox(height: 24),

          // ===================== IMAGE PICKER =====================
          const Text(
            'Event Image',
            style: TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),

          InkWell(
            onTap: isUploadingImage ? null : pickImage,
            borderRadius: BorderRadius.circular(15),
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFFCACACA)),
              ),
              child: selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.file(selectedImage!, fit: BoxFit.cover),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.add_photo_alternate, size: 50, color: Color(0xFF9C9C9C)),
                        SizedBox(height: 8),
                        Text(
                          'Tap to select image',
                          style: TextStyle(color: Color(0xFF9C9C9C), fontFamily: 'Poppins'),
                        ),
                      ],
                    ),
            ),
          ),

          if (selectedImage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 5),
                  const Text(
                    'Image selected',
                    style: TextStyle(color: Colors.green, fontSize: 12, fontFamily: 'Poppins'),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        selectedImage = null;
                      });
                    },
                    child: const Text(
                      'Remove',
                      style: TextStyle(color: Colors.red, fontFamily: 'Poppins'),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 20),

          // ===================== FORM FIELDS =====================
          _buildInputField(label: 'Event Name', controller: nameC),
          const SizedBox(height: 15),

          _buildInputField(label: 'Description', controller: descC, maxLines: 3),
          const SizedBox(height: 15),

          _buildInputField(label: 'Location', controller: locationC),
          const SizedBox(height: 15),

          _buildInputField(label: 'Organizer', controller: organizerC),
          const SizedBox(height: 15),

          _buildInputField(
            label: 'Participants Quota',
            controller: quotaC,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 15),

          // DATE PICKER
          _buildDateField(),
          const SizedBox(height: 25),

          // ACTIVE TOGGLE
          SwitchListTile(
            title: const Text(
              "Active Event",
              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500),
            ),
            subtitle: const Text(
              "Event akan tampil di dashboard",
              style: TextStyle(fontSize: 12, fontFamily: 'Poppins'),
            ),
            value: isActive,
            onChanged: (v) => setState(() => isActive = v),
            activeThumbColor: const Color(0xFF594AFC),
          ),

          const SizedBox(height: 30),

          // SAVE BUTTON
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF594AFC),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 9.5,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: isUploadingImage ? null : saveEvent,
                child: Center(
                  child: isUploadingImage
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Save Event',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Poppins',
                          ),
                        ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 12,
            fontWeight: FontWeight.w400,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFCACACA), width: 1),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              fontFamily: 'Poppins',
            ),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date',
          style: TextStyle(
            color: Colors.black,
            fontSize: 12,
            fontWeight: FontWeight.w400,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 5),
        InkWell(
          onTap: pickDate,
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFCACACA), width: 1),
            ),
            child: Row(
              children: [
                Text(
                  "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Poppins',
                  ),
                ),
                const Spacer(),
                const Icon(Icons.calendar_today, size: 16, color: Color(0xFF594AFC)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
