import 'dart:async';
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
  static const Color kPrimary  = Color(0xFF9CCB7A);
  static const Color kGrey900  = Color(0xFF818898);
  static const Color kGrey400  = Color(0xFFB3B3B3);
  static const Color kRed      = Color(0xFFD32F2F);

  // [PERF] Font constants — created once
  static final _titleStyle        = GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.w700);
  static final _searchTextStyle   = GoogleFonts.tajawal(fontSize: 14);
  static final _searchHintStyle   = GoogleFonts.tajawal(fontSize: 14, color: kGrey400);
  static final _emptyTextStyle    = GoogleFonts.tajawal(fontSize: 14, color: kGrey900);
  static final _dateLabelStyle    = GoogleFonts.tajawal(fontSize: 16, fontWeight: FontWeight.w700);
  static final _dialogTitleStyle  = GoogleFonts.tajawal(fontWeight: FontWeight.bold);
  static final _dialogContentStyle= GoogleFonts.tajawal();
  static final _dialogButtonStyle = GoogleFonts.tajawal(color: Colors.white);
  static final _navLabelStyle     = GoogleFonts.tajawal(fontSize: 11, fontWeight: FontWeight.w500);
  static final _navLabelActiveStyle = GoogleFonts.tajawal(fontSize: 11, fontWeight: FontWeight.w700);

  final TextEditingController _searchController = TextEditingController();

  // [PERF] Pre-parsed items — all heavy work done once at load time
  List<_ParsedItem> _allHistory      = [];
  List<_ParsedItem> _filteredHistory = [];
  bool    _isLoading = true;
  String? _userId;

  // [PERF] Debounce timer — search fires 300ms after last keystroke
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final user = await AuthService.getCurrentUser();
    if (user == null) { setState(() => _isLoading = false); return; }
    _userId = user['user_id'];

    final result = await ScanService.getScanHistoryCached(userId: _userId!);
    final raw = result.success ? (result.data as List? ?? []) : [];
    final rawList = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();

    // [PERF] Parse ALL heavy data here — jsonDecode, split, fromJsonList
    // None of this runs inside build() or itemBuilder
    final parsed = rawList.map((item) {
      List<String> allergens = [];
      try {
        allergens = List<String>.from(
            jsonDecode(item['found_allergens'] ?? '[]'));
      } catch (_) {}

      final ingredientsText = (item['ingredients_text'] ?? '') as String;
      final ingredients = ingredientsText.isNotEmpty
          ? ingredientsText
              .split('|||')
              .map<String>((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList()
          : <String>[];

      List<AlternativeProduct> savedAlts = [];
      try {
        savedAlts = AlternativesService.fromJsonList(
            item['alternatives_json'] ?? '[]');
      } catch (_) {}

      return _ParsedItem(
        raw: item,
        allergens: allergens,
        ingredients: ingredients,
        savedAlternatives: savedAlts,
      );
    }).toList();

    if (mounted) {
      setState(() {
        _allHistory      = parsed;
        _filteredHistory = parsed;
        _isLoading       = false;
      });
    }
  }

  // [PERF] Debounce: setState fires only after 300ms of no typing
  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _filterHistory);
  }

  void _filterHistory() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredHistory = query.isEmpty
          ? _allHistory
          : _allHistory.where((item) {
              final name = (item.raw['product_name'] ?? '')
                  .toString().toLowerCase();
              final allergens = (item.raw['found_allergens'] ?? '')
                  .toString().toLowerCase();
              return name.contains(query) || allergens.contains(query);
            }).toList();
    });
  }

  String _getDateLabel(String scanDate) {
    final date = DateTime.tryParse(scanDate);
    if (date == null) return 'قبل ذلك';
    final now       = DateTime.now();
    final today     = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final itemDate  = DateTime(date.year, date.month, date.day);
    if (itemDate == today)     return 'اليوم';
    if (itemDate == yesterday) return 'أمس';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(String scanDate) {
    final date = DateTime.tryParse(scanDate);
    if (date == null) return '';
    final hour   = date.hour;
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
          title:   Text('حذف السجل', style: _dialogTitleStyle),
          content: Text('هل تريد حذف جميع الفحوصات؟', style: _dialogContentStyle),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('إلغاء', style: _dialogContentStyle),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: kRed),
              child: Text('حذف الكل', style: _dialogButtonStyle),
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

  Future<void> _deleteSingle(Map<String, dynamic> raw) async {
    final historyId = raw['history_id'] as int?;
    if (historyId == null || _userId == null) return;
    await ScanService.deleteSingleScan(
      userId:    _userId!,
      historyId: historyId,
      scanDate:  raw['scan_date']?.toString() ?? '',
    );
    HomeScreen.clearCache();
    _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    final Color kBackground = Theme.of(context).scaffoldBackgroundColor;
    final Color kFieldBg    = Theme.of(context).cardColor;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: kBackground,
        body: SafeArea(
          child: Column(
            children: [
              // ── Header ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                            color: kFieldBg, shape: BoxShape.circle),
                        child: Icon(Icons.arrow_back,
                            color: Theme.of(context).colorScheme.onSurface,
                            size: 20),
                      ),
                    ),
                    const Spacer(),
                    Text('سجل الفحوصات',
                        style: _titleStyle.copyWith(
                            color: Theme.of(context).colorScheme.onSurface)),
                    const Spacer(),
                    if (_allHistory.isNotEmpty)
                      GestureDetector(
                        onTap: _deleteAll,
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                              color: kRed.withOpacity(0.1),
                              shape: BoxShape.circle),
                          child: Icon(Icons.delete_outline,
                              color: kRed, size: 20),
                        ),
                      )
                    else
                      const SizedBox(width: 40),
                  ],
                ),
              ),

              // ── Search bar ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                      color: kFieldBg,
                      borderRadius: BorderRadius.circular(12)),
                  child: TextField(
                    controller: _searchController,
                    textAlign: TextAlign.right,
                    style: _searchTextStyle.copyWith(
                        color: Theme.of(context).colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: 'ابحث في السجل',
                      hintStyle: _searchHintStyle,
                      prefixIcon:
                          Icon(Icons.search, color: kGrey400, size: 22),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── List ─────────────────────────────────────────────────
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredHistory.isEmpty
                        ? Center(
                            child: Text('لا توجد فحوصات بعد!',
                                style: _emptyTextStyle))
                        : _buildList(),
              ),

              // ── Bottom nav ───────────────────────────────────────────
              Container(
                height: 70,
                decoration: BoxDecoration(color: kBackground),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(Icons.home, 'الرئيسية', false,
                        () => Get.to(() => const HomeScreen())),
                    _buildNavItem(Icons.history, 'السجل', true, () {}),
                    _buildNavItem(Icons.description_outlined, 'محتوى توعوي',
                        false, () => Get.to(() => const ArticlesListScreen())),
                    _buildNavItem(Icons.person_outline, 'الملف الشخصي', false,
                        () => Get.to(() => const ProfileScreen())),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    // Group by date label
    final Map<String, List<_ParsedItem>> grouped = {};
    for (final item in _filteredHistory) {
      final label = _getDateLabel(item.raw['scan_date'] ?? '');
      grouped.putIfAbsent(label, () => []).add(item);
    }

    // [PERF] Flatten to a single list for ListView.builder
    // Only visible items are built — no full upfront render
    final List<Object> flat = [];
    for (final entry in grouped.entries) {
      flat.add(_SectionLabel(entry.key));
      flat.addAll(entry.value);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: flat.length + 1, // +1 for bottom spacer
      itemBuilder: (context, index) {
        // Bottom spacer
        if (index == flat.length) return const SizedBox(height: 80);

        final entry = flat[index];

        // Section header
        if (entry is _SectionLabel) {
          return Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 12),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text('${entry.label}:',
                  style: _dateLabelStyle.copyWith(
                      color: Theme.of(context).colorScheme.onSurface)),
            ),
          );
        }

        // History item — all data already parsed, no work here
        final item = entry as _ParsedItem;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Dismissible(
            key: Key('scan_${item.raw['history_id']}'),
            direction: DismissDirection.startToEnd,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                  color: kRed.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16)),
              child: Icon(Icons.delete_outline, color: kRed, size: 28),
            ),
            confirmDismiss: (_) async {
              await _deleteSingle(item.raw);
              return false;
            },
            child: ProductCard(
              productName:    item.raw['product_name'] ?? 'فحص مكونات',
              remoteImageUrl: (item.raw['remote_image_url'] ?? '') as String,
              localImagePath: (item.raw['local_image_path'] ?? '') as String,
              isSafe:         item.raw['safety_status'] == 'safe',
              time:           _formatTime(item.raw['scan_date'] ?? ''),
              onTap: () {
                if (item.raw['safety_status'] == 'safe') {
                  Get.to(() => SafeResultScreen(
                        productName:    item.raw['product_name'] ?? '',
                        ingredients:    item.ingredients,
                        allergens:      item.allergens,
                        localImagePath: (item.raw['local_image_path'] ?? '') as String,
                        remoteImageUrl: (item.raw['remote_image_url'] ?? '') as String,
                      ));
                } else {
                  Get.to(() => UnsafeResultScreen(
                        productName:    item.raw['product_name'] ?? '',
                        ingredients:    item.ingredients,
                        detectedAllergens: item.allergens,
                        localImagePath: (item.raw['local_image_path'] ?? '') as String,
                        remoteImageUrl: (item.raw['remote_image_url'] ?? '') as String,
                        savedAlternatives: item.savedAlternatives.isNotEmpty
                            ? item.savedAlternatives
                            : null,
                      ));
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(
      IconData icon, String label, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: isActive ? kPrimary : kGrey900, size: 26),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: isActive
                  ? _navLabelActiveStyle.copyWith(color: kPrimary)
                  : _navLabelStyle.copyWith(color: kGrey900)),
        ]),
      ),
    );
  }
}

// [PERF] Pre-parsed history item — heavy parsing done once at load time
class _ParsedItem {
  final Map<String, dynamic>   raw;
  final List<String>           allergens;
  final List<String>           ingredients;
  final List<AlternativeProduct> savedAlternatives;

  const _ParsedItem({
    required this.raw,
    required this.allergens,
    required this.ingredients,
    required this.savedAlternatives,
  });
}

// [PERF] Marker object for section headers in flat ListView
class _SectionLabel {
  final String label;
  const _SectionLabel(this.label);
}