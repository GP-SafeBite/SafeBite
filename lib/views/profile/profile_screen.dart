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

  // ✅ Problem 3 Solution: Font constants
  static final _userNameStyle = GoogleFonts.tajawal(fontSize: 20, fontWeight: FontWeight.w700);
  static final _userEmailStyle = GoogleFonts.tajawal(fontSize: 14, color: kGrey900);
  static final _sectionTitleStyle = GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.w700);
  static final _settingItemStyle = GoogleFonts.tajawal(fontSize: 15, fontWeight: FontWeight.w500);
  static final _allergyLabelStyle = GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.w600);
  static final _editButtonStyle = GoogleFonts.tajawal(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white);
  static final _emptyTextStyle = GoogleFonts.tajawal(fontSize: 14, color: kGrey900);
  static final _navLabelStyle = GoogleFonts.tajawal(fontSize: 11, fontWeight: FontWeight.w500);
  static final _navLabelActiveStyle = GoogleFonts.tajawal(fontSize: 11, fontWeight: FontWeight.w700);

  String _userName = '';
  String _userEmail = '';
  String _userPhotoUrl = '';
  String _cachedPhotoPath = '';
  int _photoVersion = 0;
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
        _photoVersion++;
        if (allergyResult.success && allergyResult.data != null) {
          _userAllergyIds = allergyResult.data as Set<String>;
        }
        _isLoading = false;
      });
    }
  }

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
                                      style: _userNameStyle.copyWith(color: Theme.of(context).colorScheme.onSurface)),
                                    const SizedBox(height: 4),
                                    Text(_userEmail, style: _userEmailStyle),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 40),
                            Text('إعدادات الحساب', style: _sectionTitleStyle.copyWith(color: Theme.of(context).colorScheme.onSurface)),
                            const SizedBox(height: 20),
                            _buildSettingItem(context: context, icon: Icons.person_outline, label: 'تعديل الملف الشخصي', cardBg: kCardBg, onTap: () async {
                              await Get.to(() => const EditProfileScreen());
                              _loadUserData(forceRefresh: true);
                            }),
                            const SizedBox(height: 16),
                            _buildSettingItem(context: context, icon: Icons.language, label: 'اللغة  (عربية)', cardBg: kCardBg, onTap: () {}),
                            const SizedBox(height: 16),
                            _buildThemeToggleItem(context: context, cardBg: kCardBg),
                            const SizedBox(height: 40),
                            Text('ملف الحساسية', style: _sectionTitleStyle.copyWith(color: Theme.of(context).colorScheme.onSurface)),
                            const SizedBox(height: 20),
                            if (_userAllergyIds.isEmpty)
                              Text('لم تختر أي حساسية بعد', style: _emptyTextStyle)
                            else
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _allAllergies
                                    .where((a) => _userAllergyIds.contains(a['id'] as String))
                                    .map((a) => _buildAllergyIcon(context: context, assetPath: a['icon'], label: a['name'], cardBg: kCardBg))
                                    .toList(),
                              ),
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: GestureDetector(
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
                                    Text('تعديل', style: _editButtonStyle),
                                  ]),
                                ),
                              ),
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
                          _buildNavItem(Icons.home, 'الرئيسية', false, () => Get.to(() => const HomeScreen())),
                          _buildNavItem(Icons.history, 'السجل', false, () => Get.to(() => const HistoryScreen())),
                          _buildNavItem(Icons.description_outlined, 'محتوى توعوي', false, () => Get.to(() => const ArticlesListScreen())),
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
            Expanded(child: Text('المظهر الداكن', style: _settingItemStyle.copyWith(color: Theme.of(context).colorScheme.onSurface))),
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
          Expanded(child: Text(label, style: _settingItemStyle.copyWith(color: Theme.of(context).colorScheme.onSurface))),
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
        Text(label, style: _allergyLabelStyle.copyWith(color: Theme.of(context).colorScheme.onSurface)),
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
          Text(label, style: isActive ? _navLabelActiveStyle.copyWith(color: kPrimary) : _navLabelStyle.copyWith(color: kGrey900)),
        ]),
      ),
    );
  }
}