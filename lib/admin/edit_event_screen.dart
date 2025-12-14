// lib/admin/edit_event_screen.dart

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../services/cloudinary_service.dart';

class EditEventScreen extends StatefulWidget {
  final String eventId;
  const EditEventScreen({super.key, required this.eventId});

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final TextEditingController nameC = TextEditingController();
  final TextEditingController descC = TextEditingController();
  final TextEditingController locationC = TextEditingController();
  final TextEditingController organizerC = TextEditingController();
  final TextEditingController quotaC = TextEditingController();
  final TextEditingController participantsC = TextEditingController();

  DateTime? selectedDate;
  bool isActive = false;
  bool loading = true;

  // IMAGE STATE
  String existingImageUrl = '';
  String existingImagePublicId = '';
  File? newSelectedImage;
  bool isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    loadEvent();
  }

  Future<void> loadEvent() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection("events")
          .doc(widget.eventId)
          .get();

      if (!doc.exists) {
        throw Exception('Event tidak ditemukan');
      }

      final data = doc.data()!;

      nameC.text = data["event_name"] ?? "";
      descC.text = data["description"] ?? "";
      locationC.text = data["location"] ?? "";
      organizerC.text = data["organizer"] ?? "";

      quotaC.text = (data["participants"] ?? 0).toString();
      participantsC.text = (data["participants_count"] ?? 0).toString();

      Timestamp ts = data["event_date"];
      selectedDate = ts.toDate();

      isActive = data["is_active"] ?? false;

      // Load existing image
      existingImageUrl = data["image_url"] ?? '';
      existingImagePublicId = data["image_public_id"] ?? '';

      setState(() => loading = false);
    } catch (e) {
      print('❌ Error loading event: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading event: $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  // FUNGSI PILIH GAMBAR BARU
  Future<void> pickNewImage() async {
    print('🔍 Opening image picker for edit...');

    await showModalBottomSheet<void>(
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
                leading: const Icon(
                  Icons.photo_library,
                  color: Color(0xFF594AFC),
                ),
                title: const Text(
                  'Pilih dari Galeri',
                  style: TextStyle(fontFamily: 'Poppins'),
                ),
                onTap: () async {
                  Navigator.pop(bottomSheetContext);

                  final XFile? image = await ImagePicker().pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 1920,
                    maxHeight: 1080,
                    imageQuality: 85,
                  );

                  if (image != null && mounted) {
                    print('✅ New image selected: ${image.path}');
                    setState(() {
                      newSelectedImage = File(image.path);
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF594AFC)),
                title: const Text(
                  'Ambil Foto',
                  style: TextStyle(fontFamily: 'Poppins'),
                ),
                onTap: () async {
                  Navigator.pop(bottomSheetContext);

                  final XFile? image = await ImagePicker().pickImage(
                    source: ImageSource.camera,
                    maxWidth: 1920,
                    maxHeight: 1080,
                    imageQuality: 85,
                  );

                  if (image != null && mounted) {
                    print('✅ New photo taken: ${image.path}');
                    setState(() {
                      newSelectedImage = File(image.path);
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.close, color: Colors.grey),
                title: const Text(
                  'Batal',
                  style: TextStyle(fontFamily: 'Poppins'),
                ),
                onTap: () => Navigator.pop(bottomSheetContext),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> updateEvent() async {
    // Validasi input
    if (nameC.text.isEmpty ||
        descC.text.isEmpty ||
        locationC.text.isEmpty ||
        organizerC.text.isEmpty ||
        quotaC.text.isEmpty ||
        participantsC.text.isEmpty ||
        selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Semua field harus diisi"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      isUploadingImage = true;
    });

    try {
      String finalImageUrl = existingImageUrl;
      String finalImagePublicId = existingImagePublicId;

      // Jika ada gambar baru, upload ke Cloudinary
      if (newSelectedImage != null) {
        print('📤 Uploading new image...');

        final uploadResult = await CloudinaryService.uploadImage(
          newSelectedImage!,
        );
        finalImageUrl = uploadResult['secure_url'];
        finalImagePublicId = uploadResult['public_id'];

        print('✅ New image uploaded successfully');
      }

      int quota = int.tryParse(quotaC.text.trim()) ?? 0;
      int participants = int.tryParse(participantsC.text.trim()) ?? 0;

      await FirebaseFirestore.instance
          .collection("events")
          .doc(widget.eventId)
          .update({
            "event_name": nameC.text.trim(),
            "description": descC.text.trim(),
            "location": locationC.text.trim(),
            "organizer": organizerC.text.trim(),
            "participants": quota,
            "participants_count": participants,
            "event_date": Timestamp.fromDate(selectedDate!),
            "is_active": isActive,
            "image_url": finalImageUrl,
            "image_public_id": finalImagePublicId,
            "updated_at": Timestamp.now(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Event berhasil diupdate!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('❌ Error updating event: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isUploadingImage = false;
        });
      }
    }
  }

  Future<void> deleteEvent() async {
    await FirebaseFirestore.instance
        .collection("events")
        .doc(widget.eventId)
        .delete();

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF594AFC)),
        ),
      );
    }

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
          'Edit Event',
          style: TextStyle(
            color: Colors.white,
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

          // ===================== IMAGE SECTION =====================
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
            onTap: isUploadingImage ? null : pickNewImage,
            borderRadius: BorderRadius.circular(15),
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFFCACACA)),
              ),
              child: _buildImageDisplay(),
            ),
          ),

          // ✅ FIXED: UI Overflow - Wrap text dalam Flexible/Expanded
          if (newSelectedImage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 16),
                  const SizedBox(width: 5),
                  const Expanded(
                    // ✅ FIXED: Tambah Expanded
                    child: Text(
                      'New image selected (will replace old one)',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        newSelectedImage = null;
                      });
                    },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.red,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (existingImageUrl.isNotEmpty && newSelectedImage == null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton.icon(
                onPressed: pickNewImage,
                icon: const Icon(Icons.edit, size: 16),
                label: const Text(
                  'Change Image',
                  style: TextStyle(fontFamily: 'Poppins'),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF594AFC),
                ),
              ),
            ),

          const SizedBox(height: 20),

          // ===================== FORM FIELDS =====================
          _buildInputField(label: 'Event Name', controller: nameC),
          const SizedBox(height: 15),

          _buildInputField(
            label: 'Description',
            controller: descC,
            maxLines: 3,
          ),
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

          _buildInputField(
            label: 'Participants Count',
            controller: participantsC,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 15),

          _buildDateField(),
          const SizedBox(height: 35),

          // Active Event Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Active Event',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Show Event in Home',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: isActive,
                  onChanged: (v) => setState(() => isActive = v),
                  activeThumbColor: const Color(0xFF594AFC),
                  inactiveThumbColor: Colors.grey[400],
                  inactiveTrackColor: Colors.grey[300],
                ),
              ),
            ],
          ),

          const SizedBox(height: 40),

          // Update Button
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
                onTap: isUploadingImage ? null : updateEvent,
                child: Center(
                  child: isUploadingImage
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Update Event',
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

          const SizedBox(height: 18),

          // Delete Button
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: const Color(0xFF9A2824), width: 1),
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
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      title: const Text(
                        'Delete Event',
                        style: TextStyle(fontFamily: 'Poppins'),
                      ),
                      content: const Text(
                        'Are you sure you want to delete this event?',
                        style: TextStyle(fontFamily: 'Poppins'),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(fontFamily: 'Poppins'),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            deleteEvent();
                          },
                          child: const Text(
                            'Delete',
                            style: TextStyle(
                              color: Color(0xFF9A2824),
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                child: const Center(
                  child: Text(
                    'Delete Event',
                    style: TextStyle(
                      color: Color(0xFF9A2824),
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

  Widget _buildImageDisplay() {
    if (newSelectedImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Image.file(newSelectedImage!, fit: BoxFit.cover),
      );
    } else if (existingImageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Image.network(
          existingImageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF594AFC)),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, size: 50, color: Color(0xFF9C9C9C)),
                SizedBox(height: 8),
                Text(
                  'Failed to load image',
                  style: TextStyle(color: Color(0xFF9C9C9C)),
                ),
              ],
            );
          },
        ),
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.add_photo_alternate, size: 50, color: Color(0xFF9C9C9C)),
          SizedBox(height: 8),
          Text(
            'No image available',
            style: TextStyle(color: Color(0xFF9C9C9C), fontFamily: 'Poppins'),
          ),
          SizedBox(height: 4),
          Text(
            'Tap to add image',
            style: TextStyle(
              color: Color(0xFF9C9C9C),
              fontSize: 12,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      );
    }
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
              contentPadding: EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 10,
              ),
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
          onTap: () async {
            final pick = await showDatePicker(
              context: context,
              initialDate: selectedDate!,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );

            if (pick != null) {
              setState(() => selectedDate = pick);
            }
          },
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
                  DateFormat('dd MMMM yyyy').format(selectedDate!),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Poppins',
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Color(0xFF594AFC),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
