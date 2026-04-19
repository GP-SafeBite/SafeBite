import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../alternatives/alternatives_screen.dart';
import '../scanning/scan_ingredients_screen.dart';
import '../../services/alternatives_service.dart';

class UnsafeResultScreen extends StatelessWidget {
  final String productName;
  final List<String> detectedAllergens;
  final List<String> detectedAllergenTypes;
  final List<String> llmSuggestedAlternatives;
  final List<Map<String, dynamic>> llmRawAlternatives;
  final String productTypeAr;
  final List ingredients;
  final List<String> traceWarnings;
  final List<AlternativeProduct>? savedAlternatives;
  final String remoteImageUrl;
  final String localImagePath;

  const UnsafeResultScreen({
    super.key,
    required this.productName,
    required this.detectedAllergens,
    this.detectedAllergenTypes = const [],
    this.llmSuggestedAlternatives = const [],
    this.llmRawAlternatives = const [],
    this.productTypeAr = '',
    required this.ingredients,
    this.traceWarnings = const [],
    this.savedAlternatives,
    this.remoteImageUrl = '',
    this.localImagePath = '',
  });

  static const Color kPrimary = Color(0xFF9CCB7A);
  static const Color kBackground = Color(0xFFFFFDF6);
  static const Color kRed = Color(0xFFD32F2F);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: kBackground,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // ── Header ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40, height: 40,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFAF6E9), shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back, size: 20),
                        ),
                      ),
                      const Spacer(),
                      Text('نتيجة الفحص',
                          style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),

                // ── Product image ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: double.infinity, height: 250,
                      color: Colors.grey.shade200,
                      child: _SmartImage(remoteUrl: remoteImageUrl, localPath: localImagePath),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                if (productName.isNotEmpty && productName != 'منتج من صورة')
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(productName,
                        style: GoogleFonts.tajawal(fontSize: 16, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center),
                  ),

                const SizedBox(height: 12),

                // ── Unsafe badge ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.cancel, color: Colors.red, size: 32),
                    const SizedBox(width: 8),
                    Flexible(child: Text('المنتج غير آمن',
                        style: GoogleFonts.tajawal(
                            fontSize: 20, fontWeight: FontWeight.bold, color: kRed),
                        overflow: TextOverflow.ellipsis)),
                  ]),
                ),

                const SizedBox(height: 20),

                // ── Detected allergens ───────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: kRed.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: kRed.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                          const SizedBox(width: 6),
                          Flexible(child: Text('مسببات الحساسية المكتشفة:',
                              style: GoogleFonts.tajawal(
                                  fontSize: 15, fontWeight: FontWeight.bold, color: kRed))),
                        ]),
                        const SizedBox(height: 10),
                        ...detectedAllergens.map((a) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(children: [
                            const Icon(Icons.circle, size: 8, color: Colors.red),
                            const SizedBox(width: 8),
                            Flexible(child: Text(a,
                                style: GoogleFonts.tajawal(
                                    fontSize: 14, color: kRed, fontWeight: FontWeight.w600))),
                          ]),
                        )),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── المواد المكتشفة — plain text list, consistent with history ─
                if (ingredients.isNotEmpty || traceWarnings.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF6E9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'المواد المكتشفة:',
                            style: GoogleFonts.tajawal(
                              fontSize: 15, fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...[
                            ...ingredients.map((e) => e.toString()),
                            ...traceWarnings,
                          ].map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                item,
                                style: GoogleFonts.tajawal(
                                  fontSize: 13,
                                  color: Colors.black87,
                                  height: 1.6,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // ── Action buttons ───────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => AlternativesScreen(
                              unsafeProductName: productName,
                              detectedAllergens: detectedAllergens,
                              detectedAllergenTypes: detectedAllergenTypes,
                              llmSuggestedAlternatives: llmSuggestedAlternatives,
                              llmRawAlternatives: llmRawAlternatives,
                              productTypeAr: productTypeAr,
                              savedAlternatives: savedAlternatives,
                            ),
                          )),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('عرض البدائل الآمنة',
                              style: GoogleFonts.tajawal(
                                  fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => Get.offAll(() => const ScanIngredientsScreen()),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: Color(0xFF9CCB7A)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('فحص منتج آخر',
                              style: GoogleFonts.tajawal(
                                  fontSize: 16, fontWeight: FontWeight.bold, color: kPrimary)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── SmartImage — UNTOUCHED ─────────────────────────────────────────────────
class _SmartImage extends StatefulWidget {
  final String remoteUrl;
  final String localPath;
  const _SmartImage({required this.remoteUrl, required this.localPath});

  @override
  State<_SmartImage> createState() => _SmartImageState();
}

class _SmartImageState extends State<_SmartImage> {
  bool get _hasLocalFile =>
      widget.localPath.isNotEmpty && File(widget.localPath).existsSync();

  @override
  Widget build(BuildContext context) {
    if (_hasLocalFile) {
      return Image.file(File(widget.localPath), fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _tryRemote());
    }
    return _tryRemote();
  }

  Widget _tryRemote() {
    if (widget.remoteUrl.isNotEmpty) {
      return Image.network(widget.remoteUrl, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            if (widget.localPath.isNotEmpty) {
              final f = File(widget.localPath);
              if (f.existsSync()) return Image.file(f, fit: BoxFit.cover);
            }
            return _placeholder();
          });
    }
    return _placeholder();
  }

  Widget _placeholder() => Center(
      child: Icon(Icons.image_not_supported, size: 60, color: Colors.grey.shade400));
}