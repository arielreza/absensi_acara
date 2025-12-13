import 'package:absensi_acara/models/event.dart';
import 'package:absensi_acara/services/auth_service.dart';
import 'package:absensi_acara/user/widgets/event_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // --- STATE VARIABLES ---
  String selectedCategory = 'All';
  final List<String> categories = ['All', 'Music', 'Art', 'Workshop'];
  final TextEditingController _searchController = TextEditingController();

  // Active Filter States
  String searchQuery = '';
  DateTime? _filterDate;
  String _filterTimeStatus = 'All'; // 'All', 'Upcoming', 'Past'
  bool _filterAvailableOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- CORE FILTER LOGIC (DIPERBAIKI AGAR AMAN DARI ERROR DATABASE) ---
  bool _shouldShowEvent(DocumentSnapshot doc, bool isCategorySection) {
    try {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return false;

      // Gunakan model Event untuk parsing aman
      final event = Event.fromFirestore(doc);

      // KONVERSI TANGGAL YANG AMAN (Handle Timestamp atau DateTime)
      DateTime eventDate;
      eventDate = (event.date).toDate();

      DateTime now = DateTime.now();

      // 1. Filter Kategori (Hanya untuk Section Bawah/Grid)
      if (isCategorySection && selectedCategory != 'All') {
        final category = data['category']?.toString() ?? 'Other';
        if (category.toLowerCase() != selectedCategory.toLowerCase()) return false;
      }

      // 2. Filter Search Bar
      if (searchQuery.isNotEmpty) {
        bool matchesName = event.name.toLowerCase().contains(searchQuery);
        bool matchesLoc = event.location.toLowerCase().contains(searchQuery);
        if (!matchesName && !matchesLoc) return false;
      }

      // 3. Filter Tanggal Spesifik
      if (_filterDate != null) {
        bool isSameDay =
            eventDate.year == _filterDate!.year &&
            eventDate.month == _filterDate!.month &&
            eventDate.day == _filterDate!.day;
        if (!isSameDay) return false;
      }

      // 4. Filter Status Waktu (Upcoming / Past)
      if (_filterTimeStatus == 'Upcoming') {
        if (eventDate.isBefore(now)) return false;
      } else if (_filterTimeStatus == 'Past') {
        if (eventDate.isAfter(now)) return false;
      }

      // 5. Filter Ketersediaan (Slot)
      if (_filterAvailableOnly) {
        int quota = (data['quota'] is int) ? data['quota'] : 0;
        List participants = (data['participants'] is List) ? data['participants'] : [];
        if (quota > 0 && participants.length >= quota) return false;
      }

      return true;
    } catch (e) {
      // Jika ada error pada satu data, jangan crash seluruh aplikasi, skip saja data ini
      debugPrint("Error filtering event ${doc.id}: $e");
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthService>().currentUser;
    final defaultName = user?.email?.split('@')[0] ?? 'User';

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- HEADER SECTION ---
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
                builder: (context, snapshot) {
                  String displayName = defaultName;
                  String initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

                  if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
                    final userData = snapshot.data!.data() as Map<String, dynamic>;
                    displayName =
                        userData['nama_lengkap'] ??
                        userData['name'] ??
                        userData['fullName'] ??
                        defaultName;
                    if (displayName.isNotEmpty) {
                      initial = displayName[0].toUpperCase();
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(24, 30, 24, 20),
                    child: Row(
                      children: [
                        // Avatar
                        Image.asset('assets/images/profile.png', width: 44, height: 44),
                        const SizedBox(width: 12),
                        // Greeting & Name
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    _getGreeting(),
                                    style: const TextStyle(
                                      color: Color(0xFF696969),
                                      fontSize: 14,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text('👋', style: TextStyle(fontSize: 14)),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                displayName,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Notification Button
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            InkWell(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Notifications clicked')),
                                );
                              },
                              borderRadius: BorderRadius.circular(17),
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFFCACACA)),
                                  color: Colors.transparent,
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.notifications_outlined,
                                    size: 18,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 2,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF68029),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),

              // --- SEARCH BAR ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(color: Color(0x0C000000), blurRadius: 8, offset: Offset(0, 0)),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Color(0xFF9C9C9C), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              searchQuery = value.toLowerCase();
                            });
                          },
                          decoration: const InputDecoration(
                            hintText: 'What event are you looking for...',
                            hintStyle: TextStyle(
                              color: Color(0xFF9C9C9C),
                              fontSize: 12,
                              fontFamily: 'Poppins',
                            ),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          style: const TextStyle(fontSize: 13, fontFamily: 'Poppins'),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.tune, color: Color(0xFF594AFC), size: 20),
                        onPressed: _showFilterDialog,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // --- FEATURED SECTION ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Featured',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    InkWell(
                      onTap: () {},
                      child: const Text(
                        'See All',
                        style: TextStyle(
                          color: Color(0xFF594AFC),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 15),

              StreamBuilder(
                // PERBAIKAN: Hapus limit database yang terlalu ketat agar filter client-side berfungsi
                stream: FirebaseFirestore.instance
                    .collection('events')
                    .where('is_active', isEqualTo: true)
                    .snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  double sectionHeight = 280;

                  // Handling Error Database
                  if (snapshot.hasError) {
                    return SizedBox(
                      height: sectionHeight,
                      child: Center(
                        child: Text(
                          "Error: ${snapshot.error}",
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SizedBox(
                      height: sectionHeight,
                      child: const Center(
                        child: CircularProgressIndicator(color: Color(0xFF594AFC)),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return SizedBox(
                      height: 100,
                      child: const Center(
                        child: Text("No featured events", style: TextStyle(color: Colors.grey)),
                      ),
                    );
                  }

                  // Filter Client Side
                  final filteredDocs = snapshot.data!.docs
                      .where((doc) => _shouldShowEvent(doc, false))
                      .take(5) // Limit hanya 5 SETELAH filter berhasil
                      .toList();

                  if (filteredDocs.isEmpty) {
                    return const SizedBox(
                      height: 100,
                      child: Center(child: Text("No matching events")),
                    );
                  }

                  return SizedBox(
                    height: sectionHeight,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 5),
                      itemCount: filteredDocs.length,
                      itemBuilder: (context, index) {
                        final doc = filteredDocs[index];
                        final event = Event.fromFirestore(doc);
                        final data = doc.data() as Map<String, dynamic>;

                        // Fallback image handling
                        final imageUrl = data['image_url'] as String? ?? event.imageUrl;

                        return EventCard(
                          event: event,
                          eventId: event.id,
                          imageUrl: imageUrl,
                          userId: user?.uid ?? '',
                        );
                      },
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // --- CATEGORIES SECTION ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Categories',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    InkWell(
                      onTap: () {},
                      child: const Text(
                        'See All',
                        style: TextStyle(
                          color: Color(0xFF594AFC),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 15),

              // Filter Chips
              SizedBox(
                height: 34,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = selectedCategory == category;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _buildCategoryChip(category, isSelected),
                    );
                  },
                ),
              ),

              const SizedBox(height: 25),

              // Category Grid
              StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('events')
                    .where('is_active', isEqualTo: true)
                    .snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text("Error loading data", style: TextStyle(color: Colors.red)),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: Text("No events found")),
                    );
                  }

                  final filteredDocs = snapshot.data!.docs
                      .where((doc) => _shouldShowEvent(doc, true))
                      .toList();

                  if (filteredDocs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: Text("No matching events")),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.72,
                        crossAxisSpacing: 19,
                        mainAxisSpacing: 20,
                      ),
                      itemCount: filteredDocs.length,
                      itemBuilder: (context, index) {
                        final doc = filteredDocs[index];
                        final event = Event.fromFirestore(doc);
                        final data = doc.data() as Map<String, dynamic>;
                        final imageUrl = data['image_url'] as String? ?? event.imageUrl;

                        return _buildVerticalEventCard(event, imageUrl, user?.uid ?? '');
                      },
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET HELPER METHODS ---

  Widget _buildCategoryChip(String category, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = category;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF594AFC) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: isSelected ? null : Border.all(color: const Color(0xFFCACACA), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (category != 'All') ...[
              Icon(
                _getCategoryIcon(category),
                size: 14,
                color: isSelected ? Colors.white : const Color(0xFF686868),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              category,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF686868),
                fontSize: 12,
                fontWeight: FontWeight.w400,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalEventCard(Event event, String? imageUrl, String userId) {
    // Handling tanggal aman
    DateTime eventDate = DateTime.now();
    try {
      eventDate = (event.date).toDate();
    } catch (e) {
      // fallback if date parsing fails
    }

    return GestureDetector(
      onTap: () {
        // Navigasi
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Opening ${event.name}')));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Color(0x19000000), blurRadius: 6, offset: Offset(0, 0)),
          ],
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFD9D9D9),
                  borderRadius: BorderRadius.circular(20),
                  image: imageUrl != null && imageUrl.isNotEmpty
                      ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                      : null,
                ),
                child: imageUrl == null || imageUrl.isEmpty
                    ? const Center(child: Icon(Icons.image, color: Colors.white54))
                    : null,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    event.name,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            DateFormat('EEE, MMM d').format(eventDate),
                            style: const TextStyle(
                              color: Color(0xFF594AFC),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Poppins',
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
                          Flexible(
                            child: Text(
                              DateFormat('HH.mm').format(eventDate),
                              style: const TextStyle(
                                color: Color(0xFF594AFC),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Poppins',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 12, color: Color(0xFF777777)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.location,
                              style: const TextStyle(
                                color: Color(0xFF777777),
                                fontSize: 11,
                                fontFamily: 'Poppins',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Music':
        return Icons.music_note_rounded;
      case 'Art':
        return Icons.palette_rounded;
      case 'Workshop':
        return Icons.work_rounded;
      default:
        return Icons.category;
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 18) return 'Good Afternoon';
    return 'Good Evening';
  }

  // --- LOGIKA FILTER MODAL (KEMBALI KE KODE AWAL YANG VALID) ---
  void _showFilterDialog() {
    DateTime? tempDate = _filterDate;
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
                bottom: MediaQuery.of(context).viewInsets.bottom + 25,
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
                    "Filter Events",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Filter Tanggal
                  const Text(
                    "Date",
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
                        builder: (context, child) {
                          return Theme(
                            data: ThemeData.light().copyWith(
                              colorScheme: const ColorScheme.light(primary: Color(0xFF594AFC)),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setModalState(() {
                          tempDate = picked;
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
                                : "Select Specific Date",
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

                  const SizedBox(height: 20),

                  // Filter Time Status
                  const Text(
                    "Time Status",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    children: ['All', 'Upcoming', 'Past'].map((status) {
                      final isSelected = tempTimeStatus == status;
                      return ChoiceChip(
                        label: Text(status),
                        selected: isSelected,
                        selectedColor: const Color(0xFF594AFC),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          fontFamily: 'Poppins',
                        ),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color: isSelected ? Colors.transparent : Colors.grey.shade300,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        onSelected: (bool selected) {
                          if (selected) {
                            setModalState(() {
                              tempTimeStatus = status;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // Filter Availability
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      "Available Seats Only",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    subtitle: const Text(
                      "Hide events that are fully booked",
                      style: TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'Poppins'),
                    ),
                    value: tempAvailableOnly,
                    activeThumbColor: const Color(0xFF594AFC),
                    onChanged: (bool value) {
                      setModalState(() {
                        tempAvailableOnly = value;
                      });
                    },
                  ),

                  const SizedBox(height: 30),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              tempDate = null;
                              tempTimeStatus = 'All';
                              tempAvailableOnly = false;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF594AFC)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: const Text(
                            "Reset",
                            style: TextStyle(color: Color(0xFF594AFC), fontFamily: 'Poppins'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _filterDate = tempDate;
                              _filterTimeStatus = tempTimeStatus;
                              _filterAvailableOnly = tempAvailableOnly;
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF594AFC),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: const Text(
                            "Apply Filter",
                            style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
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
}
