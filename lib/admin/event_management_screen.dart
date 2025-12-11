// lib/admin/event_management_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'add_event_screen.dart';
import 'edit_event_screen.dart';

// Import halaman navigasi
import 'admin_home.dart';
import 'scan_screen.dart';

class EventManagementScreen extends StatefulWidget {
  const EventManagementScreen({super.key});

  @override
  State<EventManagementScreen> createState() => _EventManagementScreenState();
}

class _EventManagementScreenState extends State<EventManagementScreen> {
  // --- STATE VARIABLES ---
  final TextEditingController _searchController = TextEditingController();

  // Categories Data
  final List<String> categories = ['All', 'Music', 'Art', 'Workshop', 'Seminar'];

  // Filter States
  String searchQuery = '';
  DateTime? _filterDate;
  DateTime? _filterMonth;
  String _filterCategory = 'All';
  String _filterTimeStatus = 'All';
  bool _filterAvailableOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- CORE FILTER LOGIC ---
  bool _shouldShowEvent(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // 1. Ambil Tanggal Event
    DateTime eventDate;
    try {
       eventDate = (data["event_date"] as Timestamp).toDate();
    } catch (e) {
       eventDate = DateTime.now();
    }
    
    DateTime now = DateTime.now();

    // 2. Filter Search Bar (Mencakup NAMA EVENT dan LOKASI)
    if (searchQuery.isNotEmpty) {
      final name = (data['event_name'] ?? '').toString().toLowerCase();
      final location = (data['location'] ?? '').toString().toLowerCase();
      
      if (!name.contains(searchQuery) && !location.contains(searchQuery)) {
        return false;
      }
    }

    // 3. Filter Kategori
    if (_filterCategory != 'All') {
      final category = (data['category'] ?? '').toString();
      if (category.toLowerCase() != _filterCategory.toLowerCase()) {
        return false;
      }
    }

    // 4. Filter Tanggal
    if (_filterDate != null) {
      bool isSameDay = eventDate.year == _filterDate!.year &&
          eventDate.month == _filterDate!.month &&
          eventDate.day == _filterDate!.day;
      if (!isSameDay) return false;
    } else if (_filterMonth != null) {
      bool isSameMonth = eventDate.year == _filterMonth!.year &&
          eventDate.month == _filterMonth!.month;
      if (!isSameMonth) return false;
    }

    // 5. Filter Status Waktu
    if (_filterTimeStatus == 'Upcoming') {
      if (eventDate.isBefore(now)) return false;
    } else if (_filterTimeStatus == 'Past') {
      if (eventDate.isAfter(now)) return false;
    }

    // 6. Filter Ketersediaan
    if (_filterAvailableOnly) {
      int quota = data['participants'] is int ? data['participants'] : 0;
      int filled = data['participants_count'] is int ? data['participants_count'] : 0;
      if (quota > 0 && filled >= quota) return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFFAFAFA),
        foregroundColor: Colors.black,
        centerTitle: true,
        title: const Text(
          "Event",
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF594AFC),
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF594AFC).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddEventScreen()),
            );
          },
        ),
      ),
      
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: "Event"),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: "Scan"),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const AdminHomeScreen()));
          } else if (index == 2) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanScreen()));
          }
        },
      ),

      body: Column(
        children: [
          // --- SEARCH BAR & FILTER ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0C000000),
                    blurRadius: 8.10,
                    offset: Offset(0, 0),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 18, color: Color(0xFF9C9C9C)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value.toLowerCase();
                        });
                      },
                      decoration: const InputDecoration(
                        hintText: 'Search event location or name...',
                        hintStyle: TextStyle(
                          color: Color(0xFF9C9C9C),
                          fontSize: 12,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w400,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(fontSize: 12, fontFamily: 'Poppins'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.tune, size: 20, color: Color(0xFF594AFC)),
                    onPressed: _showFilterDialog,
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),

          // --- EVENT LIST ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("events")
                  .orderBy("event_date", descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF594AFC)),
                  );
                }
                
                final allDocs = snapshot.data?.docs;
                
                if (allDocs == null || allDocs.isEmpty) {
                  return const Center(
                    child: Text(
                      "Belum ada event",
                      style: TextStyle(
                        color: Color(0xFF777777),
                        fontSize: 14,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  );
                }

                final filteredDocs = allDocs.where(_shouldShowEvent).toList();

                if (filteredDocs.isEmpty) {
                   return const Center(
                    child: Text(
                      "Tidak ada event yang cocok",
                      style: TextStyle(
                        color: Color(0xFF777777),
                        fontSize: 14,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  separatorBuilder: (_, __) => const SizedBox(height: 15),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final event = doc.data() as Map<String, dynamic>;
                    final eventId = doc.id;
                    final date = (event["event_date"] as Timestamp).toDate();

                    final dateStr = _formatDate(date);
                    final timeStr = _formatTime(date);
                    
                    // AMBIL IMAGE URL
                    final imageUrl = event["image_url"] ?? '';

                    return Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x19000000),
                            blurRadius: 6,
                            offset: Offset(0, 0),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ===================== IMAGE THUMBNAIL =====================
                          if (imageUrl.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                imageUrl,
                                height: 120,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    height: 120,
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        color: Color(0xFF594AFC),
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                    ),
                                  );
                                },
                              ),
                            ),
                          
                          if (imageUrl.isNotEmpty) const SizedBox(height: 12),
                          
                          Text(
                            event["event_name"] ?? "-",
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Text(
                                dateStr,
                                style: const TextStyle(
                                  color: Color(0xFF594AFC),
                                  fontSize: 12,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Container(
                                width: 3,
                                height: 3,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF594AFC),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                timeStr,
                                style: const TextStyle(
                                  color: Color(0xFF594AFC),
                                  fontSize: 12,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 7),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: Color(0xFF777777),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  event["location"] ?? "Location not set",
                                  style: const TextStyle(
                                    color: Color(0xFF777777),
                                    fontSize: 12,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w400,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Container(
                                  height: 45,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x11000000),
                                        blurRadius: 9.5,
                                        offset: Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () => _showDeleteDialog(context, eventId),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: const Color(0xFF9A2824),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        Icon(Icons.delete_outline, size: 18),
                                        SizedBox(width: 5),
                                        Text(
                                          'Delete',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontFamily: 'Poppins',
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Container(
                                  height: 45,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x11000000),
                                        blurRadius: 9.5,
                                        offset: Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => EditEventScreen(eventId: eventId),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: const Color(0xFF594AFC),
                                      elevation: 0,
                                      side: const BorderSide(width: 1, color: Color(0xFF594AFC)),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        Icon(Icons.edit_outlined, size: 18),
                                        SizedBox(width: 5),
                                        Text(
                                          'Edit Event',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontFamily: 'Poppins',
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- FILTER DIALOG UI ---
  void _showFilterDialog() {
    DateTime? tempDate = _filterDate;
    DateTime? tempMonth = _filterMonth;
    String tempCategory = _filterCategory;
    String tempTimeStatus = _filterTimeStatus;
    bool tempAvailableOnly = _filterAvailableOnly;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 25,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 25
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Filter Options",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Date Filter
                  const Text(
                    "Specific Date",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: tempDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setModalState(() {
                          tempDate = picked;
                          tempMonth = null;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFCACACA)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            tempDate != null
                                ? DateFormat('EEE, d MMM yyyy').format(tempDate!)
                                : "Select Date",
                            style: TextStyle(
                              color: tempDate != null ? Colors.black : Colors.grey,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const Icon(Icons.calendar_today, size: 18, color: Color(0xFF594AFC)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  
                  // Month Filter
                  const Text(
                    "Or Select Month",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: tempMonth ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                        helpText: "SELECT ANY DAY IN THE MONTH",
                      );
                      if (picked != null) {
                        setModalState(() {
                          tempMonth = picked;
                          tempDate = null;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFCACACA)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            tempMonth != null
                                ? DateFormat('MMMM yyyy').format(tempMonth!)
                                : "Select Month",
                            style: TextStyle(
                              color: tempMonth != null ? Colors.black : Colors.grey,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const Icon(
                            Icons.calendar_view_month,
                            size: 18,
                            color: Color(0xFF594AFC),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  
                  // Category Filter
                  const Text(
                    "Category",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.map((cat) {
                      final isSelected = tempCategory == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        selectedColor: const Color(0xFF594AFC),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          fontFamily: 'Poppins',
                          fontSize: 12
                        ),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color: isSelected ? Colors.transparent : Colors.grey.shade300,
                          ),
                          borderRadius: BorderRadius.circular(20)
                        ),
                        onSelected: (bool selected) {
                          if (selected) {
                            setModalState(() {
                              tempCategory = cat;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  
                  // Info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.info_outline, size: 18, color: Colors.blue),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Use the Search Bar to filter by Location.",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              tempDate = null;
                              tempMonth = null;
                              tempCategory = 'All';
                              tempTimeStatus = 'All';
                              tempAvailableOnly = false;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF594AFC)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: const Text(
                            "Reset",
                            style: TextStyle(
                              color: Color(0xFF594AFC),
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _filterDate = tempDate;
                              _filterMonth = tempMonth;
                              _filterCategory = tempCategory;
                              _filterTimeStatus = tempTimeStatus;
                              _filterAvailableOnly = tempAvailableOnly;
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF594AFC),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: const Text(
                            "Apply Filter",
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- HELPERS ---
  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _showDeleteDialog(BuildContext context, String eventId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Event',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'Are you sure you want to delete this event?',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF777777), fontFamily: 'Poppins'),
            ),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection("events")
                  .doc(eventId)
                  .delete();
              Navigator.pop(ctx);
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Color(0xFF9A2824),
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}