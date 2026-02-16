// lib/views/educational/articles_list_screen.dart
import 'package:flutter/material.dart';
import 'package:get_x/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safebite/views/home/home_screen.dart';
import '../../widgets/article_card.dart';
import '../history/history_screen.dart';
import '../profile/profile_screen.dart';

class ArticlesListScreen extends StatefulWidget {
  const ArticlesListScreen({super.key});

  @override
  State<ArticlesListScreen> createState() => _ArticlesListScreenState();
}

class _ArticlesListScreenState extends State<ArticlesListScreen> {
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
                      'المحتوى التوعوي',
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
                      hintText: 'بحث',
                      hintStyle: GoogleFonts.tajawal(
                        fontSize: 14,
                        color: kGrey400,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: kGrey400,
                        size: 22,
                      ),
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

              // ========== ARTICLES LIST ==========
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    // مقال 1
                    ArticleCard(
                      title: 'احم نفسك: الدليل الشامل لحساسية الطعام',
                      imageUrl: '',
                      onTap: () {
                        // TODO: navigate to article detail
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // مقال 2
                    ArticleCard(
                      title: 'الغذاء والدواء": علاج حساسية الطعام هو تجنب المكونات المسببة لها',
                      imageUrl: '',
                      onTap: () {
                        // TODO: navigate to article detail
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // مقال 3
                    ArticleCard(
                      title: 'تحليل حساسية الطعام',
                      imageUrl: '',
                      onTap: () {
                        // TODO: navigate to article detail
                      },
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
                      Get.offAll(() => HomeScreen());
                    }),
                    _buildNavItem(Icons.history, 'السجل', false, () {
                      Get.offAll(() => HistoryScreen());
                    }),
                    _buildNavItem(Icons.description_outlined, 'محتوى توعوي', true, () {
                      // already here
                    }),
                    _buildNavItem(Icons.person_outline, 'الملف الشخصي', false, () {
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

  // ========== WIDGETS ==========

  Widget _buildNavItem(IconData icon, String label, bool isActive, VoidCallback onTap) {
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