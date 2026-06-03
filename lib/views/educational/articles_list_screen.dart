// Educational Content Screen - Browse SFDA and MOH articles with search functionality

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safebite/views/home/home_screen.dart';
import '../../models/article_model.dart';
import '../../services/articles_service.dart';
import '../../widgets/article_card.dart';
import '../history/history_screen.dart';
import '../profile/profile_screen.dart';
import 'article_detail_screen.dart';

class ArticlesListScreen extends StatefulWidget {
  const ArticlesListScreen({super.key});

  @override
  State<ArticlesListScreen> createState() => _ArticlesListScreenState();
}

class _ArticlesListScreenState extends State<ArticlesListScreen> {
  static const Color kPrimary = Color(0xFF9CCB7A);
  static const Color kGrey900 = Color(0xFF818898);
  static const Color kGrey400 = Color(0xFFB3B3B3);

  static final _titleStyle = GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.w700);
  static final _searchTextStyle = GoogleFonts.tajawal(fontSize: 14);
  static final _searchHintStyle = GoogleFonts.tajawal(fontSize: 14, color: kGrey400);
  static final _emptyTextStyle = GoogleFonts.tajawal(fontSize: 14, color: kGrey900);
  static final _navLabelStyle = GoogleFonts.tajawal(fontSize: 11, fontWeight: FontWeight.w500);
  static final _navLabelActiveStyle = GoogleFonts.tajawal(fontSize: 11, fontWeight: FontWeight.w700);

  final TextEditingController _searchController = TextEditingController();

  List<ArticleModel> _allArticles = [];
  List<ArticleModel> _filteredArticles = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadArticles();
    _searchController.addListener(_filterArticles);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Article Loading Methods ───────────────────────────────────
  // Fetch all articles from Supabase with error handling
  Future<void> _loadArticles() async {
    try {
      final articles = await ArticlesService.fetchAllArticles();
      if (mounted) {
        setState(() {
          _allArticles = articles;
          _filteredArticles = articles;
          _isLoading = false;
          _errorMessage =
              articles.isEmpty ? 'لا توجد مقالات متاحة حالياً' : null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'فشل تحميل المقالات. تحقق من الاتصال';
        });
      }
    }
  }

  // ── Search and Filter Methods ─────────────────────────────────
  // Filter articles by title or description based on search query
  void _filterArticles() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredArticles = query.isEmpty
          ? _allArticles
          : _allArticles.where((a) {
              return a.title.toLowerCase().contains(query) ||
                  a.description.toLowerCase().contains(query);
            }).toList();
    });
  }

  // ── Main UI Build Method ──────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final Color kBackground = Theme.of(context).scaffoldBackgroundColor;
    final Color kFieldBg = Theme.of(context).cardColor;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: kBackground,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Get.back();
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: kFieldBg,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          size: 20,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'المحتوى التوعوي',
                      style: _titleStyle.copyWith(color: Theme.of(context).colorScheme.onSurface),
                    ),
                    const Spacer(),
                    const SizedBox(width: 40),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: kFieldBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    textAlign: TextAlign.right,
                    style: _searchTextStyle.copyWith(color: Theme.of(context).colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: 'بحث',
                      hintStyle: _searchHintStyle,
                      prefixIcon: Icon(
                        Icons.search,
                        color: kGrey400,
                        size: 22,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                        ? Center(
                            child: Text(
                              _errorMessage!,
                              style: _emptyTextStyle,
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20),
                            itemCount: _filteredArticles.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final article = _filteredArticles[index];
                              return ArticleCard(
                                title: article.title,
                                imageUrl: article.imageUrl,
                                onTap: () {
                                  Get.to(() => ArticleDetailScreen(
                                        article: article,
                                      ));
                                },
                              );
                            },
                          ),
              ),

              Container(
                height: 70,
                decoration: BoxDecoration(
                  color: kBackground,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(Icons.home, 'الرئيسية', false, () => Get.to(() => const HomeScreen())),
                    _buildNavItem(Icons.history, 'السجل', false, () => Get.to(() => const HistoryScreen())),
                    _buildNavItem(Icons.description_outlined, 'محتوى توعوي', true, () {}),
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
              style: isActive ? _navLabelActiveStyle.copyWith(color: kPrimary) : _navLabelStyle.copyWith(color: kGrey900),
            ),
          ],
        ),
      ),
    );
  }
}