// Safe Result Screen - Display product safety results and detected ingredients

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:safebite/views/history/history_screen.dart';
import '../scanning/scan_ingredients_screen.dart';
import '../home/home_screen.dart';

class SafeResultScreen extends StatelessWidget {
  final String productName;
  final String remoteImageUrl;
  final String localImagePath;
  final List ingredients;
  final List allergens;

  const SafeResultScreen({
    super.key,
    required this.productName,
    this.remoteImageUrl = '',
    this.localImagePath = '',
    required this.ingredients,
    required this.allergens,
  });

  static const Color kPrimary = Color(0xFF9CCB7A);

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
                        remoteUrl: remoteImageUrl,
                        localPath: localImagePath,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Product Name ──────────────────────────────────────────────
                if (productName.isNotEmpty && productName != 'منتج من صورة')
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      productName,
                      style: GoogleFonts.tajawal(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                const SizedBox(height: 12),

                // ── Safety Status ──────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 32,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'المنتج آمن',
                      style: GoogleFonts.tajawal(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: kPrimary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Detected Ingredients ──────────────────────────────────────
                if (ingredients.isNotEmpty)
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'المواد المكتشفة:',
                            style: GoogleFonts.tajawal(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: ingredients
                                .map(
                                  (e) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).scaffoldBackgroundColor,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: kPrimary.withOpacity(0.4),
                                      ),
                                    ),
                                    child: Text(
                                      e.toString(),
                                      style: GoogleFonts.tajawal(fontSize: 13),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // ── Safety Confirmation ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          'لا يحتوي على مسببات حساسيتك',
                          style: GoogleFonts.tajawal(
                            fontSize: 14,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // ── Scan Another Button ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        HomeScreen.clearCache();
                        Get.to(() => const ScanIngredientsScreen());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'فحص منتج آخر',
                        style: GoogleFonts.tajawal(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
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
  Widget _placeholder() => const Center(
    child: Icon(Icons.image_not_supported, size: 60, color: Colors.grey),
  );
}
