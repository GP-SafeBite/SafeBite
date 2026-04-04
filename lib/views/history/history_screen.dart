import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert'; // 🔴 added
import 'package:safebite/views/home/home_screen.dart';
import '../../services/auth_service.dart'; // 🔴 added
import '../../services/scan_service.dart'; // 🔴 added
import '../../widgets/product_card.dart';
import '../educational/articles_list_screen.dart';
import '../profile/profile_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const Color kPrimary = Color(0xFF9CCB7A);
  static const Color kBackground = Color(0xFFFFFDF6);
  static const Color kFieldBg = Color(0xFFFAF6E9);
  static const Color kGrey900 = Color(0xFF818898);
  static const Color kGrey400 = Color(0xFFB3B3B3);

  final TextEditingController _searchController = TextEditingController();

  // 🔴 added: real data variables
  List<Map<String, dynamic>> _allHistory = [];
  List<Map<String, dynamic>> _filteredHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory(); // 🔴 added
    // 🔴 added: filter when search changes
    _searchController.addListener(_filterHistory);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 🔴 added: load real history from SQLite
  Future<void> _loadHistory() async {
    final user = await AuthService.getCurrentUser();
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    final result = await ScanService.getScanHistory(
      userId: user['user_id'],
    );

    if (mounted) {
      setState(() {
        _allHistory = result.success
            ? List<Map<String, dynamic>>.from(result.data ?? [])
            : [];
        _filteredHistory = _allHistory;
        _isLoading = false;
      });
    }
  }

  // 🔴 added: filter history by product name
  void _filterHistory() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredHistory = query.isEmpty
          ? _allHistory
          : _allHistory.where((item) {
              final name =
                  (item['product_name'] ?? '').toString().toLowerCase();
              return name.contains(query);
            }).toList();
    });
  }

  // 🔴 added: group history by date section
  String _getDateLabel(String scanDate) {
    final date = DateTime.tryParse(scanDate);
    if (date == null) return 'قبل ذلك';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final itemDate = DateTime(date.year, date.month, date.day);

    if (itemDate == today) return 'اليوم';
    if (itemDate == yesterday) return 'أمس';
    return '${date.day}/${date.month}/${date.year}';
  }

  // 🔴 added: format time from scan_date
  String _formatTime(String scanDate) {
    final date = DateTime.tryParse(scanDate);
    if (date == null) return '';
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'م' : 'ص';
    final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$period$hour12:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: kBackground,
        body: SafeArea(
          child: Column(
            children: [
              // ========== HEADER ==========
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Get.back();
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: kFieldBg,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.black,
                          size: 20,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'سجل الفحوصات',
                      style: GoogleFonts.tajawal(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 40),
                  ],
                ),
              ),

              // ========== SEARCH BAR ==========
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: kFieldBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.tajawal(
                      fontSize: 14,
                      color: Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: 'ابحث في السجل',
                      hintStyle: GoogleFonts.tajawal(
                        fontSize: 14,
                        color: kGrey400,
                      ),
                      prefixIcon:
                          Icon(Icons.search, color: kGrey400, size: 22),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ========== HISTORY LIST ==========
              Expanded(
                child: _isLoading
                    // 🔴 added: show spinner while loading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredHistory.isEmpty
                        // 🔴 added: show empty state
                        ? Center(
                            child: Text(
                              'لا توجد فحوصات بعد!',
                              style: GoogleFonts.tajawal(
                                fontSize: 14,
                                color: kGrey900,
                              ),
                            ),
                          )
                        // 🔴 changed: show real history grouped by date
                        : _buildHistoryList(),
              ),

              // ========== BOTTOM NAVIGATION ==========
              Container(
                height: 70,
                decoration: const BoxDecoration(
                  color: kBackground,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(Icons.home, 'الرئيسية', false, () {
                      Get.offAll(() => HomeScreen());
                    }),
                    _buildNavItem(Icons.history, 'السجل', true, () {
                      // already here
                    }),
                    _buildNavItem(
                        Icons.description_outlined, 'محتوى توعوي', false,
                        () {
                      Get.offAll(() => ArticlesListScreen());
                    }),
                    _buildNavItem(
                        Icons.person_outline, 'الملف الشخصي', false, () {
                      Get.offAll(() => ProfileScreen());
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔴 added: builds history list grouped by date
  Widget _buildHistoryList() {
    // Group items by date label
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (final item in _filteredHistory) {
      final label = _getDateLabel(item['scan_date'] ?? '');
      grouped.putIfAbsent(label, () => []);
      grouped[label]!.add(item);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        for (final entry in grouped.entries) ...[
          _buildDateSection(entry.key),
          const SizedBox(height: 12),
          for (final item in entry.value) ...[
            _buildHistoryItem(
              time: _formatTime(item['scan_date'] ?? ''),
              productName: item['product_name'] ?? 'منتج غير معروف',
              isSafe: item['safety_status'] == 'safe',
              imageUrl: item['product_image_url'] ?? '',
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 80),
      ],
    );
  }

  // ========== WIDGETS ==========

  Widget _buildDateSection(String title) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        '$title:',
        style: GoogleFonts.tajawal(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildHistoryItem({
    required String time,
    required String productName,
    required bool isSafe,
    required String imageUrl,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: ProductCard(
        productName: productName,
        imageUrl: imageUrl,
        isSafe: isSafe,
        time: time,
        onTap: () {
          // TODO: روح لتفاصيل المنتج
        },
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    bool isActive,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: Icon(
                icon,
                color: isActive ? kPrimary : kGrey900,
                size: 26,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.tajawal(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? kPrimary : kGrey900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
