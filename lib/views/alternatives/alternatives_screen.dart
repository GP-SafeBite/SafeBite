// Alternatives Screen - Safe product alternatives based on detected allergens

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../../services/alternatives_service.dart';

class AlternativesScreen extends StatefulWidget {
  final String unsafeProductName;
  final List<String> detectedAllergens;
  final List<String> detectedAllergenTypes;
  final List<String> llmSuggestedAlternatives;
  final List<Map<String, dynamic>> llmRawAlternatives;
  final String productTypeAr;
  final List<AlternativeProduct>? savedAlternatives;

  const AlternativesScreen({
    super.key,
    this.unsafeProductName = '',
    this.detectedAllergens = const [],
    this.detectedAllergenTypes = const [],
    this.llmSuggestedAlternatives = const [],
    this.llmRawAlternatives = const [],
    this.productTypeAr = '',
    this.savedAlternatives,
  });

  @override
  State<AlternativesScreen> createState() => _AlternativesScreenState();
}

class _AlternativesScreenState extends State<AlternativesScreen> {
  static const Color kGrey900 = Color(0xFF818898);
  static const Color kPrimary = Color(0xFF9CCB7A);
  static const Color kRed = Color(0xFFD32F2F);
  static const Color kYellow = Color(0xFFF5A623);

  List<AlternativeProduct> _alternatives = [];
  bool _isLoading = true;
  bool _llmExpanded = false;

  @override
  void initState() {
    super.initState();
    if (widget.savedAlternatives != null) {
      _alternatives = widget.savedAlternatives!;
      _isLoading = false;
    } else {
      _loadAlternatives();
    }
  }

  // ── Alternative Loading Methods ───────────────────────────────
  // Fetch alternatives from Supabase based on allergen types
  Future<void> _loadAlternatives() async {
    try {
      final results = await AlternativesService.getAlternatives(
        allUserAllergyTypes: widget.detectedAllergenTypes,
        llmSuggestedAlternatives: widget.llmSuggestedAlternatives,
        llmRawAlternatives: widget.llmRawAlternatives,
        productTypeAr: widget.productTypeAr,
      );
      if (mounted) setState(() { _alternatives = results; _isLoading = false; });
    } catch (e) {
      print('Alternatives error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Main UI Build Method ──────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final Color kBackground = Theme.of(context).scaffoldBackgroundColor; 
    final Color kCardBg = Theme.of(context).cardColor; 

    // Separate alternatives into database products (id != -1) and AI-generated (id == -1)
    final dbProducts = _alternatives.where((a) => a.id != -1).toList();
    final llmProducts = _alternatives.where((a) => a.id == -1).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: kBackground, 
        body: SafeArea(
          child: Column(
            children: [
              // ── Header ────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: kCardBg,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.arrow_back,
                            color: Theme.of(context).colorScheme.onSurface, size: 20),
                      ),
                    ),
                    const Spacer(),
                    Text('البدائل الآمنة',
                      style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface), 
                    ),
                    const Spacer(),
                    const SizedBox(width: 40),
                  ],
                ),
              ),

              // ── Allergen Banner ───────────────────────────────────────────
              if (widget.detectedAllergens.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kRed.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'بدائل آمنة لـ: ${widget.detectedAllergens.join('، ')}',
                      style: GoogleFonts.tajawal(fontSize: 14, color: kRed, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),

              // ── Body ──────────────────────────────────────────────────────
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : (dbProducts.isEmpty && llmProducts.isEmpty)
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.search_off, size: 60, color: Color(0xFFD1D1D1)),
                                const SizedBox(height: 16),
                                Text('لا توجد بدائل متاحة حالياً',
                                    style: GoogleFonts.tajawal(fontSize: 16, color: kGrey900)),
                              ],
                            ),
                          )
                        : ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            children: [
                              if (dbProducts.isNotEmpty) ...[
                                _buildSectionHeader('متاح في السوق السعودي', Colors.green),
                                const SizedBox(height: 12),
                                ...dbProducts.map((p) => _buildProductCard(p, isLlm: false, kCardBg: kCardBg)),
                                const SizedBox(height: 20),
                              ],

                              if (llmProducts.isNotEmpty) ...[
                                _buildLlmToggleButton(llmProducts.length),
                                if (_llmExpanded) ...[
                                  const SizedBox(height: 12),
                                  _buildLlmDisclaimer(),
                                  const SizedBox(height: 12),
                                  ...llmProducts.map((p) => _buildProductCard(p, isLlm: true, kCardBg: kCardBg)),
                                ],
                              ],

                              const SizedBox(height: 40),
                            ],
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── LLM Products Toggle Methods ───────────────────────────────
  // Toggle visibility of AI-generated alternatives with count badge
  Widget _buildLlmToggleButton(int count) {
    return GestureDetector(
      onTap: () => setState(() => _llmExpanded = !_llmExpanded),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: kYellow.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kYellow.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Icon(_llmExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: kYellow, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text('بحث عن بدائل إضافية',
                style: GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.w700, color: kYellow),
                textAlign: TextAlign.right),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: kYellow.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
              child: Text('$count', style: GoogleFonts.tajawal(fontSize: 12, fontWeight: FontWeight.bold, color: kYellow)),
            ),
          ],
        ),
      ),
    );
  }

  // Warning message for unverified AI-generated alternatives
  Widget _buildLlmDisclaimer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kYellow.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kYellow.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: kYellow.withOpacity(0.8), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'هذه بدائل مقترحة بواسطة الذكاء الاصطناعي وقد لا تكون متوفرة جميعها في المتاجر السعودية',
              style: GoogleFonts.tajawal(fontSize: 12, color: kGrey900, height: 1.5),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(title,
        style: GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
    );
  }

  // ── Product Card Builder ──────────────────────────────────────
  // Build product card with different styling for database vs AI products
  Widget _buildProductCard(AlternativeProduct product, {required bool isLlm, required Color kCardBg}) {
    final cardColor = isLlm ? kYellow : Colors.green;
    final borderColor = cardColor.withOpacity(0.3);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 70, height: 70,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            clipBehavior: Clip.hardEdge,
            child: product.imageUrl.isNotEmpty
                ? Image.network(
                    product.imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (ctx, child, progress) => progress == null
                        ? child
                        : Center(child: CircularProgressIndicator(strokeWidth: 2, color: cardColor.withOpacity(0.5))),
                    errorBuilder: (_, __, ___) => _imagePlaceholder(isLlm),
                  )
                : _imagePlaceholder(isLlm),
          ),
          const SizedBox(width: 12),
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
                  Text(product.brand,
                    style: GoogleFonts.tajawal(fontSize: 12, color: kGrey900),
                    textAlign: TextAlign.right),
                ],
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: cardColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: cardColor.withOpacity(isLlm ? 0.5 : 0.4)),
                    ),
                    child: Text(
                      isLlm ? 'قد لا يكون متاحاً في السوق السعودي' : 'متاح في السوق السعودي',
                      style: GoogleFonts.tajawal(fontSize: 11,
                          color: isLlm ? kYellow : Colors.green.shade700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder(bool isLlm) {
    return Center(child: Icon(Icons.shopping_bag_outlined, size: 30,
        color: isLlm ? kYellow.withOpacity(0.5) : Colors.green.shade300));
  }
}