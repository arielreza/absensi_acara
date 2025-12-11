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

  // Category State
  String selectedCategory = 'All';
  final List<String> categories = ['All', 'Music', 'Art', 'Workshop'];

  // Search Controller
  final TextEditingController _searchController = TextEditingController();

  // Active Filter States
  String searchQuery = '';
  DateTime? _filterDate; // Filter: Tanggal Spesifik
  String _filterTimeStatus = 'All'; // Filter: 'All', 'Upcoming', 'Past'
  bool _filterAvailableOnly = false; // Filter: Hanya yang belum full

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- CORE FILTER LOGIC ---
  bool _shouldShowEvent(DocumentSnapshot doc, bool isCategorySection) {
    final data = doc.data() as Map<String, dynamic>;
    final event = Event.fromFirestore(doc);

    // 1. Konversi Tanggal Event ke DateTime
    DateTime eventDate = (event.date).toDate();
    DateTime now = DateTime.now();

    // 2. Filter Kategori (Hanya berlaku untuk Section Category di bawah)
    if (isCategorySection && selectedCategory != 'All') {
      final category = data['category']?.toString() ?? 'Other';
      if (category.toLowerCase() != selectedCategory.toLowerCase()) return false;
    }

    // 3. Filter Search Bar
    if (searchQuery.isNotEmpty) {
      bool matchesName = event.name.toLowerCase().contains(searchQuery);
      bool matchesLoc = event.location.toLowerCase().contains(searchQuery);
      if (!matchesName && !matchesLoc) return false;
    }

    // 4. Filter Tanggal (Spesifik Tanggal)
    if (_filterDate != null) {
      bool isSameDay =
          eventDate.year == _filterDate!.year &&
          eventDate.month == _filterDate!.month &&
          eventDate.day == _filterDate!.day;
      if (!isSameDay) return false;
    }

    // 5. Filter Status Waktu (Upcoming / Past)
    if (_filterTimeStatus == 'Upcoming') {
      if (eventDate.isBefore(now)) return false;
    } else if (_filterTimeStatus == 'Past') {
      if (eventDate.isAfter(now)) return false;
    }

    // 6. Filter Ketersediaan (Slot Belum Penuh)
    if (_filterAvailableOnly) {
      int quota = data['quota'] is int ? data['quota'] : 0;
      List participants = data['participants'] is List ? data['participants'] : [];
      if (quota > 0 && participants.length >= quota) return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    // Ambil User ID dari Auth
    final user = context.read<AuthService>().currentUser;
    // Default fallback name jika loading
    final defaultName = user?.email?.split('@')[0] ?? 'User';

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- HEADER SECTION (DIPERBAIKI) ---
              // Menggunakan StreamBuilder untuk mengambil Nama Lengkap dari Firestore 'users'
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users') // Pastikan collection di Firestore bernama 'users'
                    .doc(user?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  String displayName = defaultName;
                  String initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

                  if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
                    final userData = snapshot.data!.data() as Map<String, dynamic>;

                    // Prioritas pengambilan nama:
                    // 1. field 'nama_lengkap' (sesuai screenshot profil)
                    // 2. field 'name'
                    // 3. field 'fullName'
                    // 4. Fallback ke defaultName (email)
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
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFF594AFC),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Center(
                            child: Text(
                              initial,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    _getGreeting(),
                                    style: const TextStyle(color: Color(0xFF696969), fontSize: 14),
                                  ),
                                  const SizedBox(width: 2),
                                  const Text('👋', style: TextStyle(fontSize: 14)),
                                ],
                              ),
                              const SizedBox(height: 2),
                              // Tampilkan Nama Lengkap di sini
                              Text(
                                displayName,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(const SnackBar(content: Text('Notifications clicked')));
                          },
                          borderRadius: BorderRadius.circular(17),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFCACACA)),
                            ),
                            child: const Center(
                              child: Icon(Icons.notifications_outlined, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // --- SEARCH BAR & FILTER BUTTON ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(color: Color(0x0C000000), blurRadius: 8, offset: Offset(0, 0)),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Color(0xFF9C9C9C), size: 18),
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
                            hintText: 'Search events...',
                            hintStyle: TextStyle(color: Color(0xFF9C9C9C), fontSize: 12),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.tune, color: Color(0xFF594AFC), size: 18),
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
                  children: [
                    const Text(
                      'Featured',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        'See All',
                        style: TextStyle(
                          color: Color(0xFF594AFC),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 15),

              StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('events')
                    .where('is_active', isEqualTo: true)
                    .limit(5)
                    .snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  double sectionHeight = 260;

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
                      height: sectionHeight,
                      child: const Center(
                        child: Text(
                          "Tidak ada event featured",
                          style: TextStyle(color: Color(0xFF9C9C9C)),
                        ),
                      ),
                    );
                  }

                  final filteredDocs = snapshot.data!.docs
                      .where((doc) => _shouldShowEvent(doc, false))
                      .toList();

                  if (filteredDocs.isEmpty) {
                    return SizedBox(
                      height: sectionHeight,
                      child: const Center(child: Text("Tidak ada event yang cocok")),
                    );
                  }

                  return SizedBox(
                    height: sectionHeight,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: filteredDocs.length,
                      itemBuilder: (context, index) {
                        final doc = filteredDocs[index];
                        final event = Event.fromFirestore(doc);
                        final data = doc.data() as Map<String, dynamic>;
                        final imageUrl = data['image_url'] as String?;
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

              const SizedBox(height: 25),

              // --- CATEGORIES SECTION ---
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'Categories',
                  style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),

              const SizedBox(height: 15),

              // Filter Chips
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = selectedCategory == category;
                    return Padding(
                      padding: const EdgeInsets.only(right: 17),
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
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("Tidak ada event"));
                  }

                  final filteredDocs = snapshot.data!.docs
                      .where((doc) => _shouldShowEvent(doc, true))
                      .toList();

                  if (filteredDocs.isEmpty) {
                    return const Center(child: Text("Tidak ada event yang cocok"));
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.8,
                        crossAxisSpacing: 19,
                        mainAxisSpacing: 20,
                      ),
                      itemCount: filteredDocs.length,
                      itemBuilder: (context, index) {
                        final doc = filteredDocs[index];
                        final event = Event.fromFirestore(doc);
                        final data = doc.data() as Map<String, dynamic>;
                        final imageUrl = data['image_url'] as String?;
                        return _buildCategoryCard(event, imageUrl, user?.uid ?? '');
                      },
                    ),
                  );
                },
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  // --- FILTER MODAL DIALOG ---
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 20),

                  // 1. Filter Tanggal
                  const Text("Date", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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
                            style: TextStyle(color: tempDate != null ? Colors.black : Colors.grey),
                          ),
                          const Icon(Icons.calendar_today, size: 18, color: Color(0xFF594AFC)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 2. Filter Time Status (Upcoming / Past)
                  const Text(
                    "Time Status",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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

                  // 3. Filter Availability (Switch)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      "Available Seats Only",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      "Hide events that are fully booked",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
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

                  // Buttons (Reset & Apply)
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
                          child: const Text("Reset", style: TextStyle(color: Color(0xFF594AFC))),
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
                          child: const Text("Apply Filter", style: TextStyle(color: Colors.white)),
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

  // --- WIDGET HELPER ---
  Widget _buildCategoryCard(Event event, String? imageUrl, String userId) {
    DateTime eventDate = (event.date).toDate();

    return GestureDetector(
      onTap: () {
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Image
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFD9D9D9),
                  borderRadius: BorderRadius.circular(20),
                  image: imageUrl != null && imageUrl.isNotEmpty
                      ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                      : null,
                ),
                child: imageUrl == null || imageUrl.isEmpty
                    ? const Center(child: Icon(Icons.event, size: 40, color: Colors.white54))
                    : null,
              ),
            ),
            // Event Details
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    event.name,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          _formatDateShort(eventDate),
                          style: const TextStyle(
                            color: Color(0xFF594AFC),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
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
                          _formatTime(eventDate),
                          style: const TextStyle(
                            color: Color(0xFF594AFC),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Color(0xFF777777)),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          event.location,
                          style: const TextStyle(
                            color: Color(0xFF777777),
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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

  Widget _buildCategoryChip(String category, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = category;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF594AFC) : Colors.transparent,
          border: Border.all(color: isSelected ? Colors.transparent : const Color(0xFFCACACA)),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getCategoryIcon(category),
              size: 14,
              color: isSelected ? Colors.white : const Color(0xFF686868),
            ),
            const SizedBox(width: 5),
            Text(
              category,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF686868),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'All':
        return Icons.apps;
      case 'Music':
        return Icons.music_note;
      case 'Art':
        return Icons.palette;
      case 'Workshop':
        return Icons.work;
      default:
        return Icons.category;
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 18) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('EEE, MMM d').format(date);
  }

  String _formatDateShort(DateTime date) {
    return DateFormat('EEE, MMM d').format(date);
  }

  String _formatTime(DateTime date) {
    return DateFormat('HH:mm a').format(date);
  }
}
