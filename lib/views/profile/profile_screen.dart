// lib/views/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safebite/views/home/home_screen.dart';
import '../history/history_screen.dart';
import '../educational/articles_list_screen.dart';
import '../onboarding/get_started_screen.dart';
import '../profile/edit_allergies_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const Color kPrimary = Color(0xFF9CCB7A);
  static const Color kBackground = Color(0xFFFFFDF6);
  static const Color kGrey900 = Color(0xFF818898);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: kBackground,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      // ===== PROFILE HEADER =====
                      Row(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFB3B3B3),
                            ),
                            child: const Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'أحمد',
                                style: GoogleFonts.tajawal(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'aaronramsdale@gmail.com',
                                style: GoogleFonts.tajawal(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: kGrey900,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),

                      // ===== إعدادات الحساب =====
                      Text(
                        'إعدادات الحساب',
                        style: GoogleFonts.tajawal(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),

                      const SizedBox(height: 20),

                      _buildSettingItem(
                        icon: Icons.person_outline,
                        label: 'تعديل الملف الشخصي',
                        onTap: () {},
                      ),

                      const SizedBox(height: 16),

                      _buildSettingItem(
                        icon: Icons.language,
                        label: 'اللغة  (عربية)',
                        onTap: () {},
                      ),

                      const SizedBox(height: 16),

                      _buildSettingItem(
                        icon: Icons.wb_sunny_outlined,
                        label: 'المظهر',
                        onTap: () {},
                      ),

                      const SizedBox(height: 40),

                      // ===== ملف الحساسية =====
                      Text(
                        'ملف الحساسية',
                        style: GoogleFonts.tajawal(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),

                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          // البيض (أقصى اليمين في RTL)
                          _buildAllergyIcon(
                            'assets/allergies14/eggs.png',
                            'البيض',
                          ),

                          const SizedBox(width: 6),

                          // الحليب
                          _buildAllergyIcon(
                            'assets/allergies14/milk.png',
                            'الحليب',
                          ),

                          const Spacer(),

                          // زر تعديل (أقصى اليسار)
                          GestureDetector(
                            onTap: () {
                              Get.to(() => const EditAllergiesScreen());
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: kPrimary,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.edit,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'تعديل',
                                    style: GoogleFonts.tajawal(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),

                      _buildSettingItem(
                        icon: Icons.info_outline,
                        label: 'حول التطبيق',
                        onTap: () {},
                      ),

                      const SizedBox(height: 16),

                      _buildSettingItem(
                        icon: Icons.logout,
                        label: 'تسجيل الخروج',
                        onTap: () {
                          Get.offAll(() => const GetStartedScreen());
                        },
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // ===== BOTTOM NAVIGATION =====
              Container(
                height: 70,
                color: kBackground,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(Icons.home, 'الرئيسية', false, () {
                      Get.offAll(() => HomeScreen());
                    }),
                    _buildNavItem(Icons.history, 'السجل', false, () {
                      Get.offAll(() => HistoryScreen());
                    }),
                    _buildNavItem(Icons.description_outlined,
                        'محتوى تعليمي', false, () {
                      Get.offAll(() => const ArticlesListScreen());
                    }),
                    _buildNavItem(
                        Icons.person_outline, 'الملف الشخصي', true, () {}),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF6E9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: Colors.black),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.tajawal(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: Color(0xFF818898),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllergyIcon(String assetPath, String label) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF6E9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            assetPath,
            width: 35,
            height: 35,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.image_outlined,
                size: 28,
                color: Color(0xFFD1D1D1),
              );
            },
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.tajawal(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
      IconData icon, String label, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? kPrimary : kGrey900,
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.tajawal(
                fontSize: 11,
                fontWeight:
                    isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? kPrimary : kGrey900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}