import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:safebite/views/home/home_screen.dart';
import '../../controllers/theme_controller.dart';
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
  static const Color kGrey900 = Color(0xFF818898);

  String _userName = '';
  String _userEmail = '';
  String _userPhotoUrl = '';
  String _cachedPhotoPath = '';
  int _photoVersion = 0; // ✅ Bug 1: force re-render on photo change
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

  Future<void> _loadUserData({bool forceRefresh = false}) async {
    final user = await AuthService.getCurrentUser();
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    final allergyResult = await ProfileService.getUserAllergens(userId: user['user_id']);
    final photoUrl = user['photo_url'] ?? '';

    // ✅ Bug 1: clear Flutter's in-memory image cache when forcing refresh
    if (forceRefresh) {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
    }

    String cachedPath = '';
    if (photoUrl.isNotEmpty) {
      cachedPath = await _getCachedPhotoPath(
        user['user_id'],
        photoUrl,
        forceRefresh: forceRefresh,
      );
    }

    if (mounted) {
      setState(() {
        _userName = user['name'] ?? '';
        _userEmail = user['email'] ?? '';
        _userPhotoUrl = photoUrl;
        _cachedPhotoPath = cachedPath;
        _photoVersion++; // ✅ Bug 1: increment version to force Widget rebuild
        if (allergyResult.success && allergyResult.data != null) {
          _userAllergyIds = allergyResult.data as Set<String>;
        }
        _isLoading = false;
      });
    }
  }

  // ✅ Bug 1: URL-based cache invalidation — detects photo changes
  static Future<String> _getCachedPhotoPath(
    String userId,
    String photoUrl, {
    bool forceRefresh = false,
  }) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final cacheFile = File('${dir.path}/profile_$userId.jpg');
      final urlFile = File('${dir.path}/profile_${userId}_url.txt');

      String cachedUrl = '';
      if (await urlFile.exists()) cachedUrl = await urlFile.readAsString();

      final urlChanged = cachedUrl != photoUrl;

      if (forceRefresh || urlChanged || !await cacheFile.exists()) {
        if (await cacheFile.exists()) await cacheFile.delete();
        final response = await http.get(Uri.parse(photoUrl)).timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) {
          await cacheFile.writeAsBytes(response.bodyBytes);
          await urlFile.writeAsString(photoUrl);
        }
      }

      if (await cacheFile.exists()) return cacheFile.path;
    } catch (e) {
      print('⚠️ Photo cache failed: $e');
    }
    return '';
  }

  // ✅ Bug 1: always use Image.file with ValueKey on modification time
  // This bypasses Flutter's in-memory network image cache entirely
  Widget _buildProfilePhoto(double size) {
    if (_cachedPhotoPath.isNotEmpty) {
      final file = File(_cachedPhotoPath);
      return Image.file(
        file,
        key: ValueKey('photo_${_photoVersion}_$_cachedPhotoPath'),
        width: size, height: size, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Icon(Icons.person, size: size * 0.5, color: Colors.white),
      );
    }
    if (_userPhotoUrl.isNotEmpty) {
      return Image.network(
        _userPhotoUrl,
        key: ValueKey('photo_network_$_photoVersion'),
        width: size, height: size, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Icon(Icons.person, size: size * 0.5, color: Colors.white),
      );
    }
    return Icon(Icons.person, size: size * 0.5, color: Colors.white);
  }

  @override
  Widget build(BuildContext context) {
    final Color kBackground = Theme.of(context).scaffoldBackgroundColor;
    final Color kCardBg = Theme.of(context).cardColor;

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
                            Row(
                              children: [
                                Container(
                                  width: 80, height: 80,
                                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFB3B3B3)),
                                  child: ClipOval(child: _buildProfilePhoto(80)),
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_userName.isEmpty ? 'مستخدم' : _userName,
                                      style: GoogleFonts.tajawal(fontSize: 20, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
                                    const SizedBox(height: 4),
                                    Text(_userEmail, style: GoogleFonts.tajawal(fontSize: 14, color: kGrey900)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 40),
                            Text('إعدادات الحساب', style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
                            const SizedBox(height: 20),
                            _buildSettingItem(context: context, icon: Icons.person_outline, label: 'تعديل الملف الشخصي', cardBg: kCardBg, onTap: () async {
                              await Get.to(() => const EditProfileScreen());
                              _loadUserData(forceRefresh: true); // ✅ force cache refresh after edit
                            }),
                            const SizedBox(height: 16),
                            _buildSettingItem(context: context, icon: Icons.language, label: 'اللغة  (عربية)', cardBg: kCardBg, onTap: () {}),
                            const SizedBox(height: 16),
                            _buildThemeToggleItem(context: context, cardBg: kCardBg),
                            const SizedBox(height: 40),
                            Text('ملف الحساسية', style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                if (_userAllergyIds.isEmpty)
                                  Text('لم تختر أي حساسية بعد', style: GoogleFonts.tajawal(fontSize: 14, color: kGrey900))
                                else
                                  ..._allAllergies
                                      .where((a) => _userAllergyIds.contains(a['id'] as String))
                                      .take(3)
                                      .map((a) => Padding(
                                            padding: const EdgeInsets.only(left: 6),
                                            child: _buildAllergyIcon(context: context, assetPath: a['icon'], label: a['name'], cardBg: kCardBg),
                                          )),
                                if (_userAllergyIds.length > 3)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 6),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                      decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(16)),
                                      child: Text('+${_userAllergyIds.length - 3}', style: GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.w700, color: kPrimary)),
                                    ),
                                  ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () async {
                                    await Get.to(() => const EditAllergiesScreen());
                                    _loadUserData();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(14)),
                                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                                      const Icon(Icons.edit, size: 16, color: Colors.white),
                                      const SizedBox(width: 4),
                                      Text('تعديل', style: GoogleFonts.tajawal(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                                    ]),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 40),
                            _buildSettingItem(context: context, icon: Icons.info_outline, label: 'حول التطبيق', cardBg: kCardBg, onTap: () => Get.to(() => const AboutAppScreen())),
                            const SizedBox(height: 16),
                            _buildSettingItem(context: context, icon: Icons.logout, label: 'تسجيل الخروج', cardBg: kCardBg, onTap: () async {
                              await AuthService.logout();
                              Get.offAll(() => const GetStartedScreen());
                            }),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      height: 70,
                      color: kBackground,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildNavItem(Icons.home, 'الرئيسية', false, () => Get.offAll(() => HomeScreen())),
                          _buildNavItem(Icons.history, 'السجل', false, () => Get.offAll(() => HistoryScreen())),
                          _buildNavItem(Icons.description_outlined, 'محتوى تعليمي', false, () => Get.offAll(() => const ArticlesListScreen())),
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

  Widget _buildThemeToggleItem({required BuildContext context, required Color cardBg}) {
    final themeController = Get.find<ThemeController>();
    return Obx(() => Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Icon(Icons.wb_sunny_outlined, size: 22, color: Theme.of(context).colorScheme.onSurface),
            const SizedBox(width: 12),
            Expanded(child: Text('المظهر الداكن', style: GoogleFonts.tajawal(fontSize: 15, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface))),
            Switch(value: themeController.isDarkMode.value, onChanged: (_) => themeController.toggleTheme(), activeColor: kPrimary),
          ]),
        ));
  }

  Widget _buildSettingItem({required BuildContext context, required IconData icon, required String label, required Color cardBg, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Icon(icon, size: 22, color: Theme.of(context).colorScheme.onSurface),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: GoogleFonts.tajawal(fontSize: 15, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface))),
          const Icon(Icons.chevron_right, size: 20, color: Color(0xFF818898)),
        ]),
      ),
    );
  }

  Widget _buildAllergyIcon({required BuildContext context, required String assetPath, required String label, required Color cardBg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Image.asset(assetPath, width: 35, height: 35, errorBuilder: (_, __, ___) => const Icon(Icons.image_outlined, size: 28, color: Color(0xFFD1D1D1))),
        const SizedBox(width: 10),
        Text(label, style: GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
      ]),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: isActive ? kPrimary : kGrey900, size: 26),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.tajawal(fontSize: 11, fontWeight: isActive ? FontWeight.w700 : FontWeight.w500, color: isActive ? kPrimary : kGrey900)),
        ]),
      ),
    );
  }
}