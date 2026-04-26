import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../home/home_screen.dart';
import '../../services/auth_service.dart';
import '../../services/scan_service.dart';
import '../../services/alternatives_service.dart';
import '../../widgets/product_card.dart';
import '../educational/articles_list_screen.dart';
import '../profile/profile_screen.dart';
import '../scanning/safe_result_screen.dart';
import '../scanning/unsafe_result_screen.dart';
import '../alternatives/alternatives_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const Color kPrimary = Color(0xFF9CCB7A);
  static const Color kGrey900 = Color(0xFF818898);
  static const Color kGrey400 = Color(0xFFB3B3B3);
  static const Color kRed = Color(0xFFD32F2F);

  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allHistory = [];
  List<Map<String, dynamic>> _filteredHistory = [];
  bool _isLoading = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _searchController.addListener(_filterHistory);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final user = await AuthService.getCurrentUser();
    if (user == null) { setState(() => _isLoading = false); return; }
    _userId = user['user_id'];

    final result = await ScanService.getScanHistoryCached(userId: _userId!);
    final raw = result.success ? (result.data as List? ?? []) : [];
    final history = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();

    if (mounted) {
      setState(() {
        _allHistory = history;
        _filteredHistory = history;
        _isLoading = false;
      });
    }
  }

  void _filterHistory() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredHistory = query.isEmpty
          ? _allHistory
          : _allHistory.where((item) {
              final name = (item['product_name'] ?? '').toString().toLowerCase();
              final allergens = (item['found_allergens'] ?? '').toString().toLowerCase();
              return name.contains(query) || allergens.contains(query);
            }).toList();
    });
  }

  String _getDateLabel(String scanDate) {
    final date = DateTime.tryParse(scanDate);
    if (date == null) return 'قبل ذلك';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final itemDate = DateTime(date.year, date.month, date.day);
    if (itemDate == today) return 'اليوم';
    if (itemDate == yesterday) return 'أمس';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(String scanDate) {
    final date = DateTime.tryParse(scanDate);
    if (date == null) return '';
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'م' : 'ص';
    final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$period$hour12:$minute';
  }

  Future<void> _deleteAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('حذف السجل', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
          content: Text('هل تريد حذف جميع الفحوصات؟', style: GoogleFonts.tajawal()),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('إلغاء', style: GoogleFonts.tajawal())),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: kRed),
              child: Text('حذف الكل', style: GoogleFonts.tajawal(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
    if (confirm == true && _userId != null) {
      await ScanService.deleteAllHistory(userId: _userId!);
      HomeScreen.clearCache();
      _loadHistory();
    }
  }

  Future<void> _deleteSingle(Map<String, dynamic> item) async {
    final historyId = item['history_id'] as int?;
    if (historyId == null || _userId == null) return;
    final scanDate = item['scan_date']?.toString() ?? '';
    await ScanService.deleteSingleScan(
      userId: _userId!,
      historyId: historyId,
      scanDate: scanDate,
    );
    HomeScreen.clearCache();
    _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    final Color kBackground = Theme.of(context).scaffoldBackgroundColor; // [FIXED Dark Mode]
    final Color kFieldBg = Theme.of(context).cardColor; // [FIXED Dark Mode]

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: kBackground, // [FIXED Dark Mode]
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: kFieldBg, shape: BoxShape.circle), // [FIXED Dark Mode]
                        child: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface, size: 20), // [FIXED Dark Mode]
                      ),
                    ),
                    const Spacer(),
                    Text('سجل الفحوصات', style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface)), // [FIXED Dark Mode]
                    const Spacer(),
                    if (_allHistory.isNotEmpty)
                      GestureDetector(
                        onTap: _deleteAll,
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(color: kRed.withOpacity(0.1), shape: BoxShape.circle),
                          child: Icon(Icons.delete_outline, color: kRed, size: 20),
                        ),
                      )
                    else
                      const SizedBox(width: 40),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(color: kFieldBg, borderRadius: BorderRadius.circular(12)), // [FIXED Dark Mode]
                  child: TextField(
                    controller: _searchController,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.tajawal(fontSize: 14, color: Theme.of(context).colorScheme.onSurface), // [FIXED Dark Mode]
                    decoration: InputDecoration(
                      hintText: 'ابحث في السجل',
                      hintStyle: GoogleFonts.tajawal(fontSize: 14, color: kGrey400),
                      prefixIcon: Icon(Icons.search, color: kGrey400, size: 22),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredHistory.isEmpty
                        ? Center(child: Text('لا توجد فحوصات بعد!', style: GoogleFonts.tajawal(fontSize: 14, color: kGrey900)))
                        : _buildHistoryList(),
              ),

              Container(
                height: 70,
                decoration: BoxDecoration(color: kBackground), // [FIXED Dark Mode]
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(Icons.home, 'الرئيسية', false, () {
                      HomeScreen.clearCache();
                      Get.back();
                    }),
                    _buildNavItem(Icons.history, 'السجل', true, () {}),
                    _buildNavItem(Icons.description_outlined, 'محتوى توعوي', false, () => Get.to(() => ArticlesListScreen())),
                    _buildNavItem(Icons.person_outline, 'الملف الشخصي', false, () => Get.to(() => ProfileScreen())),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final item in _filteredHistory) {
      final label = _getDateLabel(item['scan_date'] ?? '');
      grouped.putIfAbsent(label, () => []);
      grouped[label]!.add(item);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        for (final entry in grouped.entries) ...[
          Align(alignment: Alignment.centerRight,
            child: Text('${entry.key}:', style: GoogleFonts.tajawal(fontSize: 16, fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface))), // [FIXED Dark Mode]
          const SizedBox(height: 12),
          for (final item in entry.value) ...[
            _buildHistoryItem(item: item),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildHistoryItem({required Map<String, dynamic> item}) {
    List<String> allergens = [];
    try { allergens = List<String>.from(jsonDecode(item['found_allergens'] ?? '[]')); } catch (_) {}

    final isSafe = item['safety_status'] == 'safe';
    final localImagePath = (item['local_image_path'] ?? '') as String;
    final remoteImageUrl = (item['remote_image_url'] ?? '') as String;
    final productName = (item['product_name'] ?? 'فحص مكونات') as String;
    final ingredientsText = (item['ingredients_text'] ?? '') as String;

    final List<String> ingredients = ingredientsText.isNotEmpty
        ? ingredientsText.split('|||').map<String>((e) => e.trim()).where((e) => e.isNotEmpty).toList()
        : <String>[];

    List<AlternativeProduct> savedAlternatives = [];
    try {
      final altJson = item['alternatives_json'] ?? '[]';
      savedAlternatives = AlternativesService.fromJsonList(altJson);
    } catch (_) {}

    return Dismissible(
      key: Key('scan_${item['history_id']}'),
      direction: DismissDirection.startToEnd,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: kRed.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
        child: Icon(Icons.delete_outline, color: kRed, size: 28),
      ),
      confirmDismiss: (_) async {
        await _deleteSingle(item);
        return false;
      },
      child: ProductCard(
        productName: productName,
        remoteImageUrl: remoteImageUrl,
        localImagePath: localImagePath,
        isSafe: isSafe,
        time: _formatTime(item['scan_date'] ?? ''),
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
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: isActive ? kPrimary : kGrey900, size: 26),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center, style: GoogleFonts.tajawal(fontSize: 11,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? kPrimary : kGrey900)),
        ]),
      ),
    );
  }
}