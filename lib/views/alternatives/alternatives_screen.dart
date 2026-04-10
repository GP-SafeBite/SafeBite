import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';

class AlternativesScreen extends StatelessWidget {
  final String unsafeProductName;
  final List<String> detectedAllergens;

  const AlternativesScreen({
    super.key,
    this.unsafeProductName = '',
    this.detectedAllergens = const [],
  });

  static const Color kBackground = Color(0xFFFFFDF6);
  static const Color kGrey900 = Color(0xFF818898);
  static const Color kPrimary = Color(0xFF9CCB7A);
  static const Color kRed = Color(0xFFD32F2F);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: kBackground,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    const Spacer(),
                    const SizedBox(width: 40),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  detectedAllergens.isNotEmpty
                      ? 'بدائل آمنة لحساسية: ${detectedAllergens.join('، ')}'
                      : 'البدائل الآمنة المقترحة',
                  style: GoogleFonts.tajawal(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
                  textAlign: TextAlign.right,
                ),
              ),

              const SizedBox(height: 24),

              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.hourglass_empty, size: 60, color: Color(0xFFD1D1D1)),
                      const SizedBox(height: 16),
                      Text(
                        'سيتم إضافة البدائل قريباً',
                        style: GoogleFonts.tajawal(fontSize: 16, color: kGrey900),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'نعمل على تجميع قائمة المنتجات المتوفرة في السوق السعودي',
                        style: GoogleFonts.tajawal(fontSize: 13, color: kGrey900),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}