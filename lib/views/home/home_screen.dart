// lib/views/main/home_screen.dart
import 'package:flutter/material.dart';
import 'package:get_x/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/product_card.dart';
import '../history/history_screen.dart';
import '../educational/articles_list_screen.dart';
import '../profile/profile_screen.dart';
import '../scanning/scan_barcode_screen.dart';
import '../scanning/scan_ingredients_screen.dart';




class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const Color kPrimary = Color(0xFF9CCB7A);
  static const Color kBackground = Color(0xFFFFFDF6);
  static const Color kCardBg = Color(0xFFFAF6E9);
  static const Color kGrey900 = Color(0xFF818898);
  static const Color kGrey400 = Color(0xFFB3B3B3);
  static const Color kRed = Color(0xFFD32F2F);

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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    // صورة البروفايل (أقصى اليمين)
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: kGrey400,
                        image: const DecorationImage(
                          image: NetworkImage('https://via.placeholder.com/150'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // النص
                    Text(
                      'مرحباً، أحمد',
                      style: GoogleFonts.tajawal(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    // الإيموجي بعد النص
                    const Text('👋', style: TextStyle(fontSize: 20)),
                    const Spacer(),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ========== أزرار المسح ==========
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    // مسح الباركود (يمين في RTL)
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: _buildScanButton(
                          title: 'مسح الباركود',
                          subtitle: 'تحقق سريع من المنتج',
                          onTap: () {
                            Get.to(() => const ScanBarcodeScreen());
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // مسح المكونات (يسار في RTL)
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: _buildScanButton(
                          title: 'مسح المكونات',
                          subtitle: 'صورة قائمة المكونات',
                          onTap: () {
                            Get.to(() => const ScanIngredientsScreen());
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ========== إحصائياتك ==========
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'إحصائياتك',
                    style: GoogleFonts.tajawal(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // كارد الإحصائيات
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    color: kCardBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // إجمالي الفحوصات
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '• إجمالي الفحوصات: ',
                              style: GoogleFonts.tajawal(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: kGrey900,
                              ),
                            ),
                            TextSpan(
                              text: '24',
                              style: GoogleFonts.tajawal(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: kGrey900,
                              ),
                            ),
                          ],
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 10),
                      // آمن وغير آمن
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '• آمن: ',
                              style: GoogleFonts.tajawal(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: kGrey900,
                              ),
                            ),
                            TextSpan(
                              text: '18',
                              style: GoogleFonts.tajawal(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: kPrimary,
                              ),
                            ),
                            TextSpan(
                              text: ' | غير آمن: ',
                              style: GoogleFonts.tajawal(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: kGrey900,
                              ),
                            ),
                            TextSpan(
                              text: '6',
                              style: GoogleFonts.tajawal(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: kRed,
                              ),
                            ),
                          ],
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ========== آخر فحص ==========
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'آخر فحص',
                    style: GoogleFonts.tajawal(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ========== كارد المنتج ==========
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildLastScanSection(),
              ),

              const Spacer(),

              // ========== BOTTOM NAVIGATION ==========
              Container(
                height: 70,
                decoration: const BoxDecoration(
                  color: kBackground,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(Icons.home, 'الرئيسية', true, () {
                      // already on home
                    }),
                    _buildNavItem(Icons.history, 'السجل', false, () {
                      Get.to(() => const HistoryScreen());
                    }),
                    _buildNavItem(Icons.description_outlined, 'محتوى توعوي', false, () {
                      Get.to(() => const ArticlesListScreen());
                    }),
                    _buildNavItem(Icons.person_outline, 'الملف الشخصي', false, () {
                      Get.to(() => const ProfileScreen());
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

  // يمكن تمرير lastProduct من controller لاحقاً
  // حالياً: null = لا توجد فحوصات، وإلا يعرض الكارد
  static const _lastProductName = 'حليب السعودية بالشوكولاتة';
  static const bool? _lastProductSafe = false; // null = لا توجد فحوصات بعد

  Widget _buildLastScanSection() {
    if (_lastProductSafe == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'لا توجد فحوصات بعد!',
            style: GoogleFonts.tajawal(
              fontSize: 14,
              color: kGrey900,
            ),
          ),
        ),
      );
    }
    return ProductCard(
      productName: _lastProductName,
      imageUrl: '',
      isSafe: _lastProductSafe!,
      onTap: () {
        debugPrint('Product card tapped!');
      },
    );
  }

  Widget _buildScanButton({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: kPrimary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.camera_alt_outlined,
              size: 56,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: GoogleFonts.tajawal(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: GoogleFonts.tajawal(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

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