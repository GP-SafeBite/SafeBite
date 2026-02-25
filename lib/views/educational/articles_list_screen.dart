import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safebite/views/home/home_screen.dart';
import '../../models/article_model.dart'; // 🔴 added
import '../../services/articles_service.dart'; // 🔴 added
import '../../widgets/article_card.dart';
import '../history/history_screen.dart';
import '../profile/profile_screen.dart';
import 'article_detail_screen.dart'; // 🔴 added

class ArticlesListScreen extends StatefulWidget {
  const ArticlesListScreen({super.key});

  @override
  State<ArticlesListScreen> createState() => _ArticlesListScreenState();
}

class _ArticlesListScreenState extends State<ArticlesListScreen> {
  static const Color kPrimary = Color(0xFF9CCB7A);
  static const Color kBackground = Color(0xFFFFFDF6);
  static const Color kFieldBg = Color(0xFFFAF6E9);
  static const Color kGrey900 = Color(0xFF818898);
  static const Color kGrey400 = Color(0xFFB3B3B3);

  final TextEditingController _searchController = TextEditingController();

  // 🔴 added: real data variables
  List<ArticleModel> _allArticles = [];
  List<ArticleModel> _filteredArticles = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadArticles(); // 🔴 added
    _searchController.addListener(_filterArticles); // 🔴 added
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 🔴 added: fetch articles from RSS feeds
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

  // 🔴 added: filter articles by search query
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: kBackground,
        body: SafeArea(
          child: Column(
            children: [
              // ========== HEADER ==========
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
                          color: Colors.black,
                          size: 20,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'المحتوى التوعوي',
                      style: GoogleFonts.tajawal(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 40),
                  ],
                ),
              ),

              // ========== SEARCH BAR ==========
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
                    style: GoogleFonts.tajawal(
                      fontSize: 14,
                      color: Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: 'بحث',
                      hintStyle: GoogleFonts.tajawal(
                        fontSize: 14,
                        color: kGrey400,
                      ),
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

              // ========== ARTICLES LIST ==========
              Expanded(
                child: _isLoading
                    // 🔴 loading spinner
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                        // 🔴 error or empty state
                        ? Center(
                            child: Text(
                              _errorMessage!,
                              style: GoogleFonts.tajawal(
                                fontSize: 14,
                                color: kGrey900,
                              ),
                            ),
                          )
                        // 🔴 real articles list
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
                                // 🔴 navigate to detail screen
                                onTap: () {
                                  Get.to(() => ArticleDetailScreen(
                                        article: article,
                                      ));
                                },
                              );
                            },
                          ),
              ),

              // ========== BOTTOM NAVIGATION ==========
              Container(
                height: 70,
                decoration: const BoxDecoration(
                  color: kBackground,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(Icons.home, 'الرئيسية', false, () {
                      Get.offAll(() => HomeScreen());
                    }),
                    _buildNavItem(Icons.history, 'السجل', false, () {
                      Get.offAll(() => HistoryScreen());
                    }),
                    _buildNavItem(
                        Icons.description_outlined, 'محتوى توعوي', true,
                        () {
                      // already here
                    }),
                    _buildNavItem(
                        Icons.person_outline, 'الملف الشخصي', false, () {
                      Get.offAll(() => ProfileScreen());
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

  // ========== WIDGETS ==========

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
