import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../../services/alternatives_service.dart';

class AlternativesScreen extends StatefulWidget {
  final String unsafeProductName;
  final List<String> detectedAllergens;
  final List<String> detectedAllergenTypes;
  final List<String> llmSuggestedAlternatives;

  const AlternativesScreen({
    super.key,
    this.unsafeProductName = '',
    this.detectedAllergens = const [],
    this.detectedAllergenTypes = const [],
    this.llmSuggestedAlternatives = const [],
  });

  @override
  State<AlternativesScreen> createState() => _AlternativesScreenState();
}

class _AlternativesScreenState extends State<AlternativesScreen> {
  static const Color kBackground = Color(0xFFFFFDF6);
  static const Color kGrey900 = Color(0xFF818898);
  static const Color kPrimary = Color(0xFF9CCB7A);
  static const Color kRed = Color(0xFFD32F2F);
  static const Color kCardBg = Color(0xFFFAF6E9);

  List<AlternativeProduct> _alternatives = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlternatives();
  }

  Future<void> _loadAlternatives() async {
    try {
      final results = await AlternativesService.getAlternatives(
        detectedAllergenTypes: widget.detectedAllergenTypes,
        llmSuggestedAlternatives: widget.llmSuggestedAlternatives,
      );
      if (mounted) setState(() { _alternatives = results; _isLoading = false; });
    } catch (e) {
      print('Alternatives error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final saudiAvailable = _alternatives.where((a) => a.availableInSaudi).toList();
    final llmOnly = _alternatives.where((a) => !a.availableInSaudi).toList();
    // ✅ [Added] Dynamic colors from Theme
    final Color kBackground = Theme.of(context).scaffoldBackgroundColor;
    final Color kCardBg = Theme.of(context).cardColor;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: kBackground,
        body: SafeArea(
          child: Column(
            children: [
              // HEADER
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(
                        width: 40, height: 40,
                        decoration: const BoxDecoration(color: Color(0xFFFAF6E9), shape: BoxShape.circle),
                        child: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
                      ),
                    ),
                    const Spacer(),
                    Text('البدائل الآمنة', style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black)),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: kCardBg, // ✅ [Added]
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
                      'البدائل الآمنة',
                      style: GoogleFonts.tajawal(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface, // ✅ [Added]
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 40),
                  ],
                ),
              ),

              // Allergens label
              if (widget.detectedAllergens.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: kRed.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      'بدائل آمنة لـ: ${widget.detectedAllergens.join('، ')}',
                      style: GoogleFonts.tajawal(fontSize: 14, color: kRed, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.right,
                    ),
              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: RichText(
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  text: TextSpan(
                    style: GoogleFonts.tajawal(fontSize: 16, height: 1.6),
                    children: [
                      TextSpan(
                        text: 'بدلاً من ',
                        style: GoogleFonts.tajawal(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface, // ✅ [Added]
                        ),
                      ),
                      TextSpan(
                        text: unsafeProductName,
                        style: GoogleFonts.tajawal(
                          fontWeight: FontWeight.w700,
                          color: kRed,
                        ),
                      ),
                      TextSpan(
                        text: '، جرب هذه الخيارات ',
                        style: GoogleFonts.tajawal(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface, // ✅ [Added]
                        ),
                      ),
                      TextSpan(
                        text: 'الآمنة',
                        style: GoogleFonts.tajawal(
                          fontWeight: FontWeight.w700,
                          color: kPrimary,
                        ),
                      ),
                      TextSpan(
                        text: ':',
                        style: GoogleFonts.tajawal(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface, // ✅ [Added]
                        ),
                      ),
                    ],
                  ),
                ),

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _alternatives.isEmpty
                        ? Center(child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.search_off, size: 60, color: Color(0xFFD1D1D1)),
                              const SizedBox(height: 16),
                              Text('لا توجد بدائل متاحة حالياً', style: GoogleFonts.tajawal(fontSize: 16, color: kGrey900)),
                            ],
                          ))
                        : ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            children: [
                              if (saudiAvailable.isNotEmpty) ...[
                                _buildSectionHeader('متاح في السوق السعودي', Colors.green),
                                const SizedBox(height: 12),
                                ...saudiAvailable.map((p) => _buildProductCard(p)),
                                const SizedBox(height: 20),
                              ],
                              if (llmOnly.isNotEmpty) ...[
                                _buildSectionHeader('قد لا يكون متاحاً في السوق السعودي', Colors.orange),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Text(
                                    'هذه المنتجات مقترحة بواسطة الذكاء الاصطناعي وقد لا تكون متوفرة محلياً',
                                    style: GoogleFonts.tajawal(fontSize: 12, color: kGrey900),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                                ...llmOnly.map((p) => _buildProductCard(p)),
                              ],
                              const SizedBox(height: 40),
                            ],
                          ),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _alternatives.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = _alternatives[index];
                    return _buildAlternativeCard(
                      context: context,
                      title: item['title']!,
                      imagePath: item['image']!,
                      cardBg: kCardBg,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
  Widget _buildAlternativeCard({
    required BuildContext context,
    required String title,
    required String imagePath,
    required Color cardBg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(title, style: GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _buildProductCard(AlternativeProduct product) {
    final isAvailable = product.availableInSaudi;
    final borderColor = isAvailable ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3);
    final badgeColor = isAvailable ? Colors.green : Colors.orange;
    final badgeText = isAvailable ? 'متاح في السعودية' : 'قد لا يكون متاحاً';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCardBg,
        color: cardBg, // ✅ [Added]
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          // ✅ FIXED: proper image loading with loading indicator and error fallback
          Container(
            width: 70, height: 70,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            clipBehavior: Clip.hardEdge,
            child: isAvailable && product.imageUrl.isNotEmpty
                ? Image.network(
                    product.imageUrl,
                    fit: BoxFit.cover,
                    width: 70,
                    height: 70,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.green.shade300,
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (_, error, __) {
                      print('❌ Image load error for ${product.imageUrl}: $error');
                      return _imagePlaceholder(isAvailable);
                    },
                  )
                : _imagePlaceholder(isAvailable),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.nameAr.isNotEmpty ? product.nameAr : product.nameEn,
                  style: GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.right,
                ),
                if (product.brand.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(product.brand, style: GoogleFonts.tajawal(fontSize: 12, color: kGrey900), textAlign: TextAlign.right),
                ],
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: badgeColor.withOpacity(0.4)),
                    ),
                    child: Text(badgeText, style: GoogleFonts.tajawal(fontSize: 11, color: badgeColor.shade700)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder(bool available) {
    return Center(
      child: Icon(
        Icons.shopping_bag_outlined,
        size: 30,
        color: available ? Colors.green.shade300 : Colors.orange.shade300,
      ),
    );
  }
}