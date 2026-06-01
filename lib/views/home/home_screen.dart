// Home Screen - Main dashboard with scan history, statistics, and navigation

import 'dart:async' show unawaited;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../widgets/product_card.dart';
import '../../services/auth_service.dart';
import '../../services/scan_service.dart';
import '../../services/alternatives_service.dart';
import '../history/history_screen.dart';
import '../educational/articles_list_screen.dart';
import '../profile/profile_screen.dart';
import '../scanning/scan_ingredients_screen.dart';
import '../scanning/safe_result_screen.dart';
import '../scanning/unsafe_result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static void clearCache() {
    _HomeScreenState._cachedUser = null;
    _HomeScreenState._cachedHistory = null;
  }

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color kPrimary = Color(0xFF9CCB7A);
  static const Color kGrey900 = Color(0xFF818898);
  static const Color kRed = Color(0xFFD32F2F);

  static final _headerStyle = GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.w600);
  static final _buttonTitleStyle = GoogleFonts.tajawal(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white);
  static final _buttonSubtitleStyle = GoogleFonts.tajawal(fontSize: 14, color: Colors.white);
  static final _sectionTitleStyle = GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.w700);
  static final _statsTextBoldStyle = GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.w600);
  static final _statsTextNormalStyle = GoogleFonts.tajawal(fontSize: 14);
  static final _statsTextColoredBoldStyle = GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.bold);
  static final _emptyTextStyle = GoogleFonts.tajawal(fontSize: 14, color: kGrey900);
  static final _navLabelStyle = GoogleFonts.tajawal(fontSize: 11, fontWeight: FontWeight.w500);
  static final _navLabelActiveStyle = GoogleFonts.tajawal(fontSize: 11, fontWeight: FontWeight.w700);

  static Map<String, dynamic>? _cachedUser;
  static List<Map<String, dynamic>>? _cachedHistory;

  String _userName = '';
  String _userPhotoUrl = '';
  String _cachedPhotoPath = '';
  int _photoVersion = 0;
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

  // ── Data Loading Methods ──────────────────────────────────────
  // Load user data from Supabase and cache scan history
  Future<void> _loadData({bool forceRefresh = false}) async {
    if (forceRefresh) {
      _cachedUser = null;
      _cachedHistory = null;
    }

    // Fetch current user from Supabase
    _cachedUser ??= await AuthService.getCurrentUser();
    if (_cachedUser == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    // Prefetch history for performance optimization
    ScanService.prefetchHistory(userId: _cachedUser!['user_id']);

    // Load scan history if not cached
    if (_cachedHistory == null) {
      final result = await ScanService.getScanHistory(userId: _cachedUser!['user_id']);
      final raw = result.success ? (result.data as List? ?? []) : [];
      _cachedHistory = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }

    // Load and cache profile photo
    final photoUrl = _cachedUser!['photo_url'] ?? '';
    String cachedPath = '';
    if (photoUrl.isNotEmpty) {
      cachedPath = await _getCachedPhotoPath(_cachedUser!['user_id'], photoUrl);
    }

    // Update UI with loaded data
    if (mounted) {
      setState(() {
        _userName = _cachedUser!['name'] ?? '';
        _userPhotoUrl = photoUrl;
        _cachedPhotoPath = cachedPath;
        _photoVersion++;
        _safeScans = _cachedHistory!.where((h) => h['safety_status'] == 'safe').length;
        _unsafeScans = _cachedHistory!.where((h) => h['safety_status'] == 'unsafe').length;
        _totalScans = _safeScans + _unsafeScans;
        _lastScan = _cachedHistory!.isNotEmpty ? _cachedHistory!.first : null;
        _isLoading = false;
      });
    }
  }

  // ── Photo Caching Methods ─────────────────────────────────────
  // Cache profile photo locally to reduce network requests
  static Future<String> _getCachedPhotoPath(String userId, String photoUrl) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final cacheFile = File('${dir.path}/profile_$userId.jpg');
      final urlFile = File('${dir.path}/profile_${userId}_url.txt');

      // Check if cached URL matches current URL
      String cachedUrl = '';
      if (await urlFile.exists()) cachedUrl = await urlFile.readAsString();

      final urlChanged = cachedUrl != photoUrl;

      // Download only if URL changed or cache doesn't exist
      if (urlChanged || !await cacheFile.exists()) {
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

  // ── Photo Display Methods ─────────────────────────────────────
  // Build profile photo with fallback to network or default icon
  Widget _buildProfilePhoto(double size) {
    if (_cachedPhotoPath.isNotEmpty) {
      return Image.file(
        File(_cachedPhotoPath),
        key: ValueKey('photo_${_photoVersion}_$_cachedPhotoPath'),
        width: size, height: size, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white, size: 28),
      );
    }
    if (_userPhotoUrl.isNotEmpty) {
      return Image.network(
        _userPhotoUrl,
        key: ValueKey('photo_network_$_photoVersion'),
        width: size, height: size, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white, size: 28),
      );
    }
    return const Icon(Icons.person, color: Colors.white, size: 28);
  }

  // ── Main UI Build Method ──────────────────────────────────────
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
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48, height: 48,
                                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFB3B3B3)),
                                    child: ClipOval(child: _buildProfilePhoto(48)),
                                  ),
                                  const SizedBox(width: 12),
                                  Flexible(
                                    child: Text('مرحباً، $_userName 👋',
                                      style: _headerStyle.copyWith(color: Theme.of(context).colorScheme.onSurface),
                                      overflow: TextOverflow.ellipsis),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 32),

                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: AspectRatio(
                                aspectRatio: 1.7,
                                child: GestureDetector(
                                  onTap: () => Get.to(() => const ScanIngredientsScreen())?.then((_) => _loadData(forceRefresh: true)),
                                  child: Container(
                                    decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(20)),
                                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                      const Icon(Icons.camera_alt_outlined, size: 56, color: Colors.white),
                                      const SizedBox(height: 16),
                                      Text('مسح المكونات', style: _buttonTitleStyle),
                                      const SizedBox(height: 6),
                                      Text('صورة قائمة المكونات', style: _buttonSubtitleStyle),
                                    ]),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 32),

                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Align(alignment: Alignment.centerRight,
                                child: Text('إحصائياتك', style: _sectionTitleStyle)),
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(16)),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text('• إجمالي الفحوصات: $_totalScans', style: _statsTextBoldStyle),
                                  const SizedBox(height: 8),
                                  Row(children: [
                                    Text('• آمن: ', style: _statsTextNormalStyle),
                                    Text('$_safeScans', style: _statsTextColoredBoldStyle.copyWith(color: kPrimary)),
                                    Text('  |  غير آمن: ', style: _statsTextNormalStyle),
                                    Text('$_unsafeScans', style: _statsTextColoredBoldStyle.copyWith(color: kRed)),
                                  ]),
                                ]),
                              ),
                            ),

                            const SizedBox(height: 32),

                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Align(alignment: Alignment.centerRight,
                                child: Text('آخر فحص', style: _sectionTitleStyle)),
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

                    Container(
                      height: 70,
                      decoration: BoxDecoration(color: kBackground),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildNavItem(Icons.home, 'الرئيسية', true, () {}),
                          _buildNavItem(Icons.history, 'السجل', false,
                            () => Get.to(() => const HistoryScreen())?.then((_) => _loadData())),
                          _buildNavItem(Icons.description_outlined, 'محتوى توعوي', false,
                            () => Get.to(() => const ArticlesListScreen())),
                          _buildNavItem(Icons.person_outline, 'الملف الشخصي', false,
                            () => Get.to(() => const ProfileScreen())?.then((_) => _loadData(forceRefresh: true))),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ── Last Scan Display Methods ─────────────────────────────────
  // Build last scan card with product details and navigation to results
  Widget _buildLastScanSection() {
    if (_lastScan == null) {
      return Center(child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text('لا توجد فحوصات بعد!', style: _emptyTextStyle),
      ));
    }

    // Parse allergens from JSON
    List<String> allergens = [];
    try { allergens = List<String>.from(jsonDecode(_lastScan!['found_allergens'] ?? '[]')); } catch (_) {}

    final isSafe = _lastScan!['safety_status'] == 'safe';
    final localImagePath = (_lastScan!['local_image_path'] ?? '') as String;
    final remoteImageUrl = (_lastScan!['remote_image_url'] ?? '') as String;
    final productName = (_lastScan!['product_name'] ?? 'فحص مكونات') as String;
    final ingredientsText = (_lastScan!['ingredients_text'] ?? '') as String;

    // Parse ingredients from pipe-separated text
    final List<String> ingredients = ingredientsText.isNotEmpty
        ? ingredientsText.split('|||').map<String>((e) => e.trim()).where((e) => e.isNotEmpty).toList()
        : <String>[];

    // Parse cached alternatives
    List<AlternativeProduct> savedAlternatives = [];
    try {
      final altJson = _lastScan!['alternatives_json'] ?? '[]';
      savedAlternatives = AlternativesService.fromJsonList(altJson);
    } catch (_) {}

    return ProductCard(
      productName: productName,
      remoteImageUrl: remoteImageUrl,
      localImagePath: localImagePath,
      isSafe: isSafe,
      onTap: () {
        if (isSafe) {
          Get.to(() => SafeResultScreen(
            productName: productName, ingredients: ingredients, allergens: allergens,
            localImagePath: localImagePath, remoteImageUrl: remoteImageUrl,
          ));
        } else {
          Get.to(() => UnsafeResultScreen(
            productName: productName, ingredients: ingredients, detectedAllergens: allergens,
            localImagePath: localImagePath, remoteImageUrl: remoteImageUrl,
            savedAlternatives: savedAlternatives.isNotEmpty ? savedAlternatives : null,
          ));
        }
      },
    );
  }

  // Navigation item for bottom nav - displays icon, label, and changes color if active
  Widget _buildNavItem(IconData icon, String label, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: isActive ? kPrimary : kGrey900, size: 26),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center,
            style: isActive ? _navLabelActiveStyle.copyWith(color: kPrimary) : _navLabelStyle.copyWith(color: kGrey900)),
        ]),
      ),
    );
  }
}