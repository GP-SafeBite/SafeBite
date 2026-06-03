// Unsafe Result Screen - Display unsafe product detection with allergen warnings and safe alternatives

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../alternatives/alternatives_screen.dart';
import '../scanning/scan_ingredients_screen.dart';
import '../../services/alternatives_service.dart';
import '../home/home_screen.dart';
import '../history/history_screen.dart';

class UnsafeResultScreen extends StatefulWidget {
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

  @override
  State<UnsafeResultScreen> createState() => _UnsafeResultScreenState();
}

class _UnsafeResultScreenState extends State<UnsafeResultScreen> {
  static const Color kPrimary = Color(0xFF9CCB7A);
  static const Color kRed = Color(0xFFD32F2F);

  late Future<List<AlternativeProduct>> _alternativesFuture;

  @override
  void initState() {
    super.initState();
    if (widget.savedAlternatives != null) {
      _alternativesFuture = Future.value(widget.savedAlternatives);
    } else {
      _alternativesFuture = Future.value(const []);
    }
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
          child: SingleChildScrollView(
            child: Column(
              children: [
                // ── Header ────────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Get.until((route) => route.isFirst),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: kCardBg,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_back,
                            color: Theme.of(context).colorScheme.onSurface,
                            size: 20,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'نتيجة الفحص',
                        style: GoogleFonts.tajawal(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),

                // ── Product Image ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: double.infinity,
                      height: 250,
                      color: Colors.grey.shade200,
                      child: _SmartImage(
                        remoteUrl: widget.remoteImageUrl,
                        localPath: widget.localImagePath,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Product Name ──────────────────────────────────────────────
                if (widget.productName.isNotEmpty &&
                    widget.productName != 'منتج من صورة')
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      widget.productName,
                      style: GoogleFonts.tajawal(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                const SizedBox(height: 12),

                // ── Safety Status ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cancel, color: Colors.red, size: 32),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'المنتج غير آمن',
                          style: GoogleFonts.tajawal(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: kRed,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Detected Allergens Warning ────────────────────────────────
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
                        Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'مسببات الحساسية المكتشفة:',
                                style: GoogleFonts.tajawal(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: kRed,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...widget.detectedAllergens.map(
                          (a) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.circle,
                                  size: 8,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    a,
                                    style: GoogleFonts.tajawal(
                                      fontSize: 14,
                                      color: kRed,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Detected Ingredients ──────────────────────────────────────
                if (widget.ingredients.isNotEmpty ||
                    widget.traceWarnings.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: kCardBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'المواد المكتشفة:',
                              style: GoogleFonts.tajawal(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: Text(
                              [
                                ...widget.ingredients.map((e) => e.toString()),
                                ...widget.traceWarnings,
                              ].join('\n'),
                              style: GoogleFonts.tajawal(
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.onSurface,
                                height: 1.6,
                              ),
                              textAlign: TextAlign.right,
                              textDirection: TextDirection.rtl,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // ── Action Buttons ────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      FutureBuilder<List<AlternativeProduct>>(
                        future: _alternativesFuture,
                        builder: (context, snapshot) {
                          final alternatives = snapshot.data;
                          final isReady =
                              snapshot.connectionState == ConnectionState.done;

                          return SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isReady
                                  ? () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AlternativesScreen(
                                          unsafeProductName: widget.productName,
                                          detectedAllergens:
                                              widget.detectedAllergens,
                                          detectedAllergenTypes:
                                              widget.detectedAllergenTypes,
                                          llmSuggestedAlternatives:
                                              widget.llmSuggestedAlternatives,
                                          llmRawAlternatives:
                                              widget.llmRawAlternatives,
                                          productTypeAr: widget.productTypeAr,
                                          savedAlternatives: alternatives,
                                        ),
                                      ),
                                    )
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isReady
                                    ? kPrimary
                                    : Colors.grey.shade300,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: isReady
                                  ? Text(
                                      'عرض البدائل الآمنة',
                                      style: GoogleFonts.tajawal(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white70,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          'جاري التحميل...',
                                          style: GoogleFonts.tajawal(
                                            fontSize: 16,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            HomeScreen.clearCache();
                            Get.to(() => const ScanIngredientsScreen());
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: Color(0xFF9CCB7A)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'فحص منتج آخر',
                            style: GoogleFonts.tajawal(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: kPrimary,
                            ),
                          ),
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

// ── Smart Image Widget ────────────────────────────────────────
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

  // ── Image Display Methods ─────────────────────────────────────
  // Display image with priority: local file > remote URL > placeholder
  @override
  Widget build(BuildContext context) {
    if (_hasLocalFile) {
      return Image.file(
        File(widget.localPath),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _tryRemote(),
      );
    }
    return _tryRemote();
  }

  // Try loading remote image if local not available
  Widget _tryRemote() {
    if (widget.remoteUrl.isNotEmpty) {
      return Image.network(
        widget.remoteUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          if (widget.localPath.isNotEmpty) {
            final f = File(widget.localPath);
            if (f.existsSync()) return Image.file(f, fit: BoxFit.cover);
          }
          return _placeholder();
        },
      );
    }
    return _placeholder();
  }

  // Show placeholder icon when no image available
  Widget _placeholder() => Center(
    child: Icon(
      Icons.image_not_supported,
      size: 60,
      color: Colors.grey.shade400,
    ),
  );
}
