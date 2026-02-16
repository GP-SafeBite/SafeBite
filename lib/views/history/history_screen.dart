// lib/views/history/history_screen.dart
import 'package:flutter/material.dart';
import 'package:get_x/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safebite/views/home/home_screen.dart';
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                    // زر الرجوع (دائرة - أقصى اليسار)
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
                    // العنوان
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
                      prefixIcon: Icon(Icons.search, color: kGrey400, size: 22),
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
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    // ========== اليوم ==========
                    _buildDateSection('اليوم:'),
                    const SizedBox(height: 12),
                    _buildHistoryItem(
                      time: 'ص11:00',
                      productName: 'حليب السعودية بالشوكولاتة',
                      isSafe: false,
                      imageUrl: '',
                    ),
                    const SizedBox(height: 24),

                    // ========== أمس ==========
                    _buildDateSection('أمس:'),
                    const SizedBox(height: 12),
                    _buildHistoryItem(
                      time: 'م11:00',
                      productName: 'أوريو OREO',
                      isSafe: false,
                      imageUrl: '',
                    ),
                    const SizedBox(height: 12),
                    _buildHistoryItem(
                      time: 'ص9:00',
                      productName: 'معمول بالتمر الفاخر',
                      isSafe: true,
                      imageUrl: '',
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
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
        Get.offAll(() => HomeScreen()); // ✅ شيلت const
      }),
      _buildNavItem(Icons.history, 'السجل', true, () {
        // already here
      }),
      _buildNavItem(Icons.description_outlined, 'محتوى توعوي', false, () {
        Get.offAll(() => ArticlesListScreen()); // ✅ شيلت const
      }),
      _buildNavItem(Icons.person_outline, 'الملف الشخصي', false, () {
        Get.offAll(() => ProfileScreen()); // ✅ شيلت const
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

  // ========== WIDGETS ==========

  Widget _buildDateSection(String title) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        title,
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
