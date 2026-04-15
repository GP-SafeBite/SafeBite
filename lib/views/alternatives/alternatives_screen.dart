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
  static const Color kBackground = Color(0xFFFFFDF6);
  static const Color kGrey900 = Color(0xFF818898);
  static const Color kPrimary = Color(0xFF9CCB7A);
  static const Color kRed = Color(0xFFD32F2F);
  static const Color kCardBg = Color(0xFFFAF6E9);
  // ✅ Issue 2: yellow for LLM alternatives
  static const Color kYellow = Color(0xFFF5A623);

  List<AlternativeProduct> _alternatives = [];
  bool _isLoading = true;

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

  Future<void> _loadAlternatives() async {
    try {
      final results = await AlternativesService.getAlternatives(
        detectedAllergenTypes: widget.detectedAllergenTypes,
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

  @override
  Widget build(BuildContext context) {
    // ✅ Issue 2: DB products = green (availableInSaudi=true, id != -1)
    //            LLM products = yellow (id == -1)
    final dbProducts = _alternatives.where((a) => a.id != -1).toList();
    final llmProducts = _alternatives.where((a) => a.id == -1).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: kBackground,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(width: 40, height: 40, decoration: const BoxDecoration(color: Color(0xFFFAF6E9), shape: BoxShape.circle), child: const Icon(Icons.arrow_back, color: Colors.black, size: 20)),
                    ),
                    const Spacer(),
                    Text('البدائل الآمنة', style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black)),
                    const Spacer(),
                    const SizedBox(width: 40),
                  ],
                ),
              ),

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
                  ),
                ),

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _alternatives.isEmpty
                        ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            const Icon(Icons.search_off, size: 60, color: Color(0xFFD1D1D1)),
                            const SizedBox(height: 16),
                            Text('لا توجد بدائل متاحة حالياً', style: GoogleFonts.tajawal(fontSize: 16, color: kGrey900)),
                          ]))
                        : ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            children: [
                              // ✅ DB products — GREEN section
                              if (dbProducts.isNotEmpty) ...[
                                _buildSectionHeader('متاح في السوق السعودي', Colors.green),
                                const SizedBox(height: 12),
                                ...dbProducts.map((p) => _buildProductCard(p, isLlm: false)),
                                const SizedBox(height: 20),
                              ],
                              // ✅ LLM products — YELLOW section
                              if (llmProducts.isNotEmpty) ...[
                                _buildSectionHeader('مقترحات الذكاء الاصطناعي', kYellow),
                                const SizedBox(height: 12),
                                ...llmProducts.map((p) => _buildProductCard(p, isLlm: true)),
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

  Widget _buildSectionHeader(String title, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.3))),
      child: Text(title, style: GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _buildProductCard(AlternativeProduct product, {required bool isLlm}) {
    // ✅ Issue 2: DB=green, LLM=yellow always
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
                ? Image.network(product.imageUrl, fit: BoxFit.cover,
                    loadingBuilder: (ctx, child, progress) => progress == null ? child
                        : Center(child: CircularProgressIndicator(strokeWidth: 2, color: cardColor.withOpacity(0.5))),
                    errorBuilder: (_, __, ___) => _imagePlaceholder(isLlm))
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
                  Text(product.brand, style: GoogleFonts.tajawal(fontSize: 12, color: kGrey900), textAlign: TextAlign.right),
                ],
                // ✅ Issue 2: removed foundInStores text entirely
                // ✅ Issue 2: LLM gets yellow badge + "may not be available" note
                const SizedBox(height: 6),
                if (isLlm) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: kYellow.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: kYellow.withOpacity(0.5)),
                      ),
                      child: Text(
                        'قد لا يكون متاحاً في السوق السعودي',
                        style: GoogleFonts.tajawal(fontSize: 11, color: kYellow),
                      ),
                    ),
                  ),
                ] else ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green.withOpacity(0.4)),
                      ),
                      child: Text(
                        'متاح في السوق السعودي',
                        style: GoogleFonts.tajawal(fontSize: 11, color: Colors.green.shade700),
                      ),
                    ),
                  ),
                ],
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