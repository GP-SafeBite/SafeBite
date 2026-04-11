// Safe.result.screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SafeResultScreen extends StatelessWidget {
  final String productName;
  final String? barcode;
  final String? imageUrl;
  final List ingredients;
  final List allergens;

  const SafeResultScreen({
    super.key,
    required this.productName,
    this.barcode,
    this.imageUrl,
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

                const SizedBox(height: 20),

                // صورة المنتج
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: imageUrl != null && imageUrl!.isNotEmpty
                            ? Image.network(
                                imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.image_not_supported, size: 80),
                              )
                            : const Icon(Icons.image_not_supported, size: 80),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // النتيجة
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 32),
                    const SizedBox(width: 8),
                    Text(
                      'المنتج آمن',
                      style: GoogleFonts.tajawal(
                        fontSize: 18,
                        color: kPrimary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // اسم المنتج
                Text(
                  'اسم المنتج: $productName',
                  style: GoogleFonts.tajawal(
                    fontSize: 15,
                    color: kGrey900,
                  ),
                ),

                const SizedBox(height: 20),

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
                ),

                const SizedBox(height: 20),

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

                // زر
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'فحص منتج آخر',
                        style: GoogleFonts.tajawal(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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