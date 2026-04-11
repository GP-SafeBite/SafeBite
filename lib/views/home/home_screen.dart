import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/product_card.dart';
import '../../services/auth_service.dart';
import '../../services/scan_service.dart';
import '../history/history_screen.dart';
import '../educational/articles_list_screen.dart';
import '../profile/profile_screen.dart';
import '../scanning/scan_ingredients_screen.dart';
import '../scanning/safe_result_screen.dart';
import '../scanning/unsafe_result_screen.dart';

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

  Future<void> _loadData() async {
    final user = await AuthService.getCurrentUser();
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final result = await ScanService.getScanHistory(userId: user['user_id']);
    final raw = result.success ? (result.data as List? ?? []) : [];
    final history = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();

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
                        child: Column(
                          children: [
                            // HEADER
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48, height: 48,
                                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFB3B3B3)),
                                    child: _userPhotoUrl.isNotEmpty
                                        ? ClipOval(child: Image.network(_bustCache(_userPhotoUrl), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white, size: 28)))
                                        : const Icon(Icons.person, color: Colors.white, size: 28),
                                  ),
                                  const SizedBox(width: 12),
                                  Flexible(
                                    child: Text('مرحباً، $_userName 👋',
                                      style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black),
                                      overflow: TextOverflow.ellipsis),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 32),

                            // SCAN BUTTON
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: GestureDetector(
                                  onTap: () => Get.to(() => const ScanIngredientsScreen())?.then((_) => _loadData()),
                                  child: Container(
                                    decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(20)),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.camera_alt_outlined, size: 56, color: Colors.white),
                                        const SizedBox(height: 16),
                                        Text('مسح المكونات', style: GoogleFonts.tajawal(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
                                        const SizedBox(height: 6),
                                        Text('صورة قائمة المكونات', style: GoogleFonts.tajawal(fontSize: 14, color: Colors.white)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 32),

                            // STATS
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Align(alignment: Alignment.centerRight, child: Text('إحصائياتك', style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.w700))),
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(16)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('• إجمالي الفحوصات: $_totalScans', style: GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 8),
                                    Row(children: [
                                      Text('• آمن: ', style: GoogleFonts.tajawal(fontSize: 14)),
                                      Text('$_safeScans', style: GoogleFonts.tajawal(fontSize: 14, color: kPrimary, fontWeight: FontWeight.bold)),
                                      Text('  |  غير آمن: ', style: GoogleFonts.tajawal(fontSize: 14)),
                                      Text('$_unsafeScans', style: GoogleFonts.tajawal(fontSize: 14, color: kRed, fontWeight: FontWeight.bold)),
                                    ]),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 32),

                            // LAST SCAN
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Align(alignment: Alignment.centerRight, child: Text('آخر فحص', style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.w700))),
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

                    // BOTTOM NAV
                    Container(
                      height: 70,
                      decoration: const BoxDecoration(color: kBackground),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildNavItem(Icons.home, 'الرئيسية', true, () {}),
                          _buildNavItem(Icons.history, 'السجل', false, () => Get.to(() => const HistoryScreen())?.then((_) => _loadData())),
                          _buildNavItem(Icons.description_outlined, 'محتوى توعوي', false, () => Get.to(() => const ArticlesListScreen())),
                          _buildNavItem(Icons.person_outline, 'الملف الشخصي', false, () => Get.to(() => const ProfileScreen())),
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
      return Center(child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text('لا توجد فحوصات بعد!', style: GoogleFonts.tajawal(fontSize: 14, color: kGrey900)),
      ));
    }

    List<String> allergens = [];
    try { allergens = List<String>.from(jsonDecode(_lastScan!['found_allergens'] ?? '[]')); } catch (_) {}

    final isSafe = _lastScan!['safety_status'] == 'safe';
    final localImagePath = _lastScan!['local_image_path'] ?? '';
    final productName = _lastScan!['product_name'] ?? 'فحص مكونات';
    final ingredientsText = (_lastScan!['ingredients_text'] ?? '') as String;

    // ✅ Fixed: explicit typed map and where
    final List<String> ingredients = ingredientsText.isNotEmpty
        ? ingredientsText
            .split(',')
            .map<String>((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList()
        : <String>[];

    return ProductCard(
      productName: productName,
  imageUrl: _lastScan!['local_image_path'] ?? '',  // ✅ Updated
  localImagePath: '',  // ✅ Updated
      isSafe: isSafe,
      onTap: () {
        if (isSafe) {
          Get.to(() => SafeResultScreen(productName: productName, ingredients: ingredients, allergens: allergens, localImagePath: localImagePath));
        } else {
          Get.to(() => UnsafeResultScreen(productName: productName, ingredients: ingredients, detectedAllergens: allergens, localImagePath: localImagePath));
        }
      },
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
            Text(label, textAlign: TextAlign.center, style: GoogleFonts.tajawal(fontSize: 11, fontWeight: isActive ? FontWeight.w700 : FontWeight.w500, color: isActive ? kPrimary : kGrey900)),
          ],
        ),
      ),
    );
  }
}