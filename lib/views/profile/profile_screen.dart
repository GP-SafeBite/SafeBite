import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safebite/views/home/home_screen.dart';
import 'package:safebite/views/profile/about_app.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../history/history_screen.dart';
import '../educational/articles_list_screen.dart';
import '../onboarding/get_started_screen.dart';
import '../profile/edit_allergies_screen.dart';
import '../profile/edit_profile_screen.dart';
import '../profile/about_app.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color kPrimary = Color(0xFF9CCB7A);
  static const Color kBackground = Color(0xFFFFFDF6);
  static const Color kGrey900 = Color(0xFF818898);

  String _userName = '';
  String _userEmail = '';
  String _userPhotoUrl = ''; // ✅ Added photo URL
  Set<String> _userAllergyIds = {};
  bool _isLoading = true;

  final List<Map<String, dynamic>> _allAllergies = [
    {'name': 'الحليب', 'icon': 'assets/allergies14/milk.png', 'id': 'milk'},
    {'name': 'البيض', 'icon': 'assets/allergies14/eggs.png', 'id': 'eggs'},
    {'name': 'القشريات', 'icon': 'assets/allergies14/crustaceans.png', 'id': 'crustaceans'},
    {'name': 'الحبوب (مثل الجلوتين)', 'icon': 'assets/allergies14/gluten.png', 'id': 'gluten'},
    {'name': 'السمك', 'icon': 'assets/allergies14/fish.png', 'id': 'fish'},
    {'name': 'فول الصويا', 'icon': 'assets/allergies14/soyabeans.png', 'id': 'soybeans'},
    {'name': 'الكرفس', 'icon': 'assets/allergies14/celery.png', 'id': 'celery'},
    {'name': 'الفول السوداني', 'icon': 'assets/allergies14/peanuts.png', 'id': 'peanuts'},
    {'name': 'المكسرات', 'icon': 'assets/allergies14/treenuts.png', 'id': 'treenuts'},
    {'name': 'الخردل', 'icon': 'assets/allergies14/mustard.png', 'id': 'mustard'},
    {'name': 'الترمس', 'icon': 'assets/allergies14/lupin.png', 'id': 'lupin'},
    {'name': 'الرخويات', 'icon': 'assets/allergies14/mollusks.png', 'id': 'mollusks'},
    {'name': 'بذورالسمسم', 'icon': 'assets/allergies14/sesame.png', 'id': 'sesame'},
    {'name': 'الكبريتيت', 'icon': 'assets/allergies14/sulfur.png', 'id': 'sulfur'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await AuthService.getCurrentUser();
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    final allergyResult = await ProfileService.getUserAllergens(
      userId: user['user_id'],
    );

    if (mounted) {
      setState(() {
        _userName = user['name'] ?? '';
        _userEmail = user['email'] ?? '';
        _userPhotoUrl = user['photo_url'] ?? ''; // ✅ Load photo URL
        if (allergyResult.success && allergyResult.data != null) {
          _userAllergyIds = allergyResult.data as Set<String>;
        }
        _isLoading = false;
      });
    }
  }

  // ✅ Cache bust helper for profile photo
  String _bustCache(String url) {
    if (url.isEmpty) return url;
    final base = url.split('?').first;
    return '$base?t=${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: kBackground,
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
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
                                // ✅ Fixed: show actual photo if available
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFFB3B3B3),
                                  ),
                                  child: _userPhotoUrl.isNotEmpty
                                      ? ClipOval(
                                          child: Image.network(
                                            _bustCache(_userPhotoUrl),
                                            width: 80,
                                            height: 80,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => const Icon(
                                              Icons.person,
                                              size: 40,
                                              color: Colors.white,
                                            ),
                                          ),
                                        )
                                      : const Icon(
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
                                      _userName.isEmpty ? 'مستخدم' : _userName,
                                      style: GoogleFonts.tajawal(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _userEmail,
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
                              onTap: () async {
                                await Get.to(() => const EditProfileScreen());
                                _loadUserData();
                              },
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
                                if (_userAllergyIds.isEmpty)
                                  Text(
                                    'لم تختر أي حساسية بعد',
                                    style: GoogleFonts.tajawal(
                                      fontSize: 14,
                                      color: kGrey900,
                                    ),
                                  )
                                else
                                  // ✅ FIX: cast a['id'] to String to match Set<String>
                                  ..._allAllergies
                                      .where((a) => _userAllergyIds.contains(a['id'] as String))
                                      .take(3)
                                      .map((a) => Padding(
                                            padding: const EdgeInsets.only(left: 6),
                                            child: _buildAllergyIcon(
                                              a['icon'],
                                              a['name'],
                                            ),
                                          )),

                                if (_userAllergyIds.length > 3)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 6),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFAF6E9),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        '+${_userAllergyIds.length - 3}',
                                        style: GoogleFonts.tajawal(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: kPrimary,
                                        ),
                                      ),
                                    ),
                                  ),

                                const Spacer(),

                                GestureDetector(
                                  onTap: () async {
                                    await Get.to(() => const EditAllergiesScreen());
                                    _loadUserData();
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
                                        const Icon(Icons.edit, size: 16, color: Colors.white),
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
                              onTap: () {
                                Get.to(() => const AboutAppScreen());
                              },
                            ),

                            const SizedBox(height: 16),

                            _buildSettingItem(
                              icon: Icons.logout,
                              label: 'تسجيل الخروج',
                              onTap: () async {
                                await AuthService.logout();
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
                          _buildNavItem(Icons.description_outlined, 'محتوى تعليمي', false, () {
                            Get.offAll(() => const ArticlesListScreen());
                          }),
                          _buildNavItem(Icons.person_outline, 'الملف الشخصي', true, () {}),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
            const Icon(Icons.chevron_right, size: 20, color: Color(0xFF818898)),
          ],
        ),
      ),
    );
  }

  Widget _buildAllergyIcon(String assetPath, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
              return const Icon(Icons.image_outlined, size: 28, color: Color(0xFFD1D1D1));
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

  Widget _buildNavItem(IconData icon, String label, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isActive ? kPrimary : kGrey900, size: 26),
            const SizedBox(height: 4),
            Text(
              label,
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