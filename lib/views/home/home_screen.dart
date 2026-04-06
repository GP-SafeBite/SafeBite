import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/product_card.dart';
import '../../services/auth_service.dart';
import '../../services/scan_service.dart';
import '../history/history_screen.dart';
import '../educational/articles_list_screen.dart';
import '../profile/profile_screen.dart';
// ✅ [Removed] import scan_barcode_screen.dart — barcode feature removed
import '../scanning/scan_ingredients_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color kPrimary = Color(0xFF9CCB7A);
  static const Color kBackground = Color(0xFFFFFDF6);
  static const Color kCardBg = Color(0xFFFAF6E9);
  static const Color kGrey900 = Color(0xFF818898);
  static const Color kGrey400 = Color(0xFFB3B3B3);
  static const Color kRed = Color(0xFFD32F2F);

  String _userName = '';
  String _userPhotoUrl = '';
  int _totalScans = 0;
  int _safeScans = 0;
  int _unsafeScans = 0;
  Map<String, dynamic>? _lastScan;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // 🔴 reload when returning from any screen
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = await AuthService.getCurrentUser();
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final result = await ScanService.getScanHistory(
      userId: user['user_id'],
    );

    final history = result.success
        ? List<Map<String, dynamic>>.from(result.data ?? [])
        : <Map<String, dynamic>>[];

    if (mounted) {
      setState(() {
        _userName = user['name'] ?? '';
        _userPhotoUrl = user['photo_url'] ?? '';
        _totalScans = history.length;
        _safeScans = history.where((h) => h['safety_status'] == 'safe').length;
        _unsafeScans = history.where((h) => h['safety_status'] == 'unsafe').length;
        _lastScan = history.isNotEmpty ? history.first : null;
        _isLoading = false;
      });
    }
  }

  // 🔴 cache busting helper
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
              // 🔴 show full loader — prevents مستخدم glitch
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        // 🔴 scrollable — fixes overflow errors
                        child: Column(
                          children: [
                            // ========== HEADER ==========
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFFB3B3B3),
                                    ),
                                    child: _userPhotoUrl.isNotEmpty
                                        ? ClipOval(
                                            child: Image.network(
                                              _bustCache(_userPhotoUrl), // 🔴 cache bust
                                              width: 48,
                                              height: 48,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) =>
                                                  const Icon(Icons.person,
                                                      color: Colors.white, size: 28),
                                            ),
                                          )
                                        : const Icon(Icons.person,
                                            color: Colors.white, size: 28),
                                  ),
                                  const SizedBox(width: 12),
                                  Flexible(
                                    child: Text(
                                      'مرحباً، $_userName 👋',
                                      style: GoogleFonts.tajawal(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 32),

                            // ========== زر المسح ==========
                            // ✅ [Removed] barcode scan button — ingredients scan only
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: GestureDetector(
                                onTap: () => Get.to(() => const ScanIngredientsScreen()),
                                child: Container(
                                  width: double.infinity,
                                  height: 160,
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
                                        'مسح المكونات',
                                        style: GoogleFonts.tajawal(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'صورة قائمة المكونات',
                                        style: GoogleFonts.tajawal(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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

                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 20, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: kCardBg,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text.rich(
                                      TextSpan(children: [
                                        TextSpan(
                                          text: '• إجمالي الفحوصات: ',
                                          style: GoogleFonts.tajawal(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: kGrey900,
                                          ),
                                        ),
                                        TextSpan(
                                          text: '$_totalScans',
                                          style: GoogleFonts.tajawal(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: kGrey900,
                                          ),
                                        ),
                                      ]),
                                      textDirection: TextDirection.rtl,
                                    ),
                                    const SizedBox(height: 10),
                                    Text.rich(
                                      TextSpan(children: [
                                        TextSpan(
                                          text: '• آمن: ',
                                          style: GoogleFonts.tajawal(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: kGrey900,
                                          ),
                                        ),
                                        TextSpan(
                                          text: '$_safeScans',
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
                                          text: '$_unsafeScans',
                                          style: GoogleFonts.tajawal(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: kRed,
                                          ),
                                        ),
                                      ]),
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

                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: _buildLastScanSection(),
                            ),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),

                    // ========== BOTTOM NAVIGATION ==========
                    Container(
                      height: 70,
                      decoration: const BoxDecoration(color: kBackground),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildNavItem(Icons.home, 'الرئيسية', true, () {}),
                          _buildNavItem(Icons.history, 'السجل', false, () {
                            Get.to(() => const HistoryScreen());
                          }),
                          _buildNavItem(
                              Icons.description_outlined, 'محتوى توعوي', false, () {
                            Get.to(() => const ArticlesListScreen());
                          }),
                          _buildNavItem(
                              Icons.person_outline, 'الملف الشخصي', false, () {
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

  Widget _buildLastScanSection() {
    if (_lastScan == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'لا توجد فحوصات بعد!',
            style: GoogleFonts.tajawal(fontSize: 14, color: kGrey900),
          ),
        ),
      );
    }

    return ProductCard(
      productName: _lastScan!['product_name'] ?? 'منتج غير معروف',
      imageUrl: _lastScan!['product_image_url'] ?? '',
      isSafe: _lastScan!['safety_status'] == 'safe',
      onTap: () => debugPrint('Product card tapped!'),
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
            SizedBox(
              width: 28,
              height: 28,
              child: Icon(icon, color: isActive ? kPrimary : kGrey900, size: 26),
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