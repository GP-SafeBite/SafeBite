import 'dart:io';
// Safe.result.screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SafeResultScreen extends StatelessWidget {
  final String productName;
  final String? imageUrl;
  final String? localImagePath;
  final List ingredients;
  final List allergens;

  const SafeResultScreen({
    super.key,
    required this.productName,
    this.imageUrl,
    this.localImagePath,
    required this.ingredients,
    required this.allergens,
  });

  static const Color kPrimary = Color(0xFF9CCB7A);
  static const Color kGrey900 = Color(0xFF818898);

  @override
  Widget build(BuildContext context) {
    // ✅ [Added] Dynamic colors from Theme
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
                // HEADER
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40, height: 40,
                          decoration: const BoxDecoration(color: Color(0xFFFAF6E9), shape: BoxShape.circle),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: kCardBg, // ✅ [Added]
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back, size: 20),
                        ),
                      ),
                      const Spacer(),
                      Text('نتيجة الفحص', style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.w700)),
                      Text(
                        'نتيجة الفحص',
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

                // ✅ Scanned image
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: double.infinity,
                      height: 250,
                      color: Colors.grey.shade200,
                      child: _buildImage(),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Product name
                if (productName.isNotEmpty && productName != 'منتج من صورة')
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(productName, style: GoogleFonts.tajawal(fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ),

                const SizedBox(height: 12),

                // Result
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 32),
                    const SizedBox(width: 8),
                    Text('المنتج آمن ✅', style: GoogleFonts.tajawal(fontSize: 20, fontWeight: FontWeight.bold, color: kPrimary)),
                  ],
                ),

                const SizedBox(height: 20),

                // ✅ Ingredients as chips
                if (ingredients.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: const Color(0xFFFAF6E9), borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('المواد المكتشفة:', style: GoogleFonts.tajawal(fontSize: 15, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: ingredients.map((e) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: kPrimary.withOpacity(0.4)),
                              ),
                              child: Text(e.toString(), style: GoogleFonts.tajawal(fontSize: 13)),
                            )).toList(),
                          ),
                        ],
                      ),
                    ),
                // المكونات
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'المكونات:',
                        style: GoogleFonts.tajawal(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface, // ✅ [Added]
                        ),
                      ),
                      const SizedBox(height: 8),
                      ingredients.isEmpty
                          ? Text(
                              'لا توجد مكونات',
                              style: GoogleFonts.tajawal(fontSize: 14),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: ingredients
                                  .map((e) => Text(
                                        "• $e",
                                        style: GoogleFonts.tajawal(fontSize: 14),
                                      ))
                                  .toList(),
                            ),
                    ],
                  ),

                const SizedBox(height: 16),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        Text('لا يحتوي على مسببات حساسيتك', style: GoogleFonts.tajawal(fontSize: 14, color: Colors.green.shade700)),
                      ],
                    ),
                // مسببات الحساسية
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مسببات الحساسية:',
                        style: GoogleFonts.tajawal(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface, // ✅ [Added]
                        ),
                      ),
                      const SizedBox(height: 8),
                      allergens.isEmpty
                          ? Text(
                              'لا يوجد',
                              style: GoogleFonts.tajawal(fontSize: 14),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: allergens
                                  .map((e) => Text(
                                        "• $e",
                                        style: GoogleFonts.tajawal(
                                          fontSize: 14,
                                          color: Colors.red,
                                        ),
                                      ))
                                  .toList(),
                            ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('فحص منتج آخر', style: GoogleFonts.tajawal(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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

  Widget _buildImage() {
    if (localImagePath != null && localImagePath!.isNotEmpty) {
      return Image.file(File(localImagePath!), fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder());
    }
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder());
    }
    return _placeholder();
  }

  Widget _placeholder() => const Center(child: Icon(Icons.image_not_supported, size: 60, color: Colors.grey));
}