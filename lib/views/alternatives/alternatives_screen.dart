import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get_x/get.dart';

class AlternativesScreen extends StatelessWidget {
  final String unsafeProductName;

  const AlternativesScreen({
    super.key,
    this.unsafeProductName = 'حليب السعودية بالشوكولاتة',
  });

  static const Color kBackground = Color(0xFFFFFDF6);
  static const Color kGrey900 = Color(0xFF818898);
  static const Color kPrimary = Color(0xFF9CCB7A);
  static const Color kRed = Color(0xFFD32F2F);

  static const List<Map<String, String>> _alternatives = [
    {
      'title': 'نوق حليب جمل طويل الأجل بالشوكولاتة',
      'image': 'assets/alternatives/product1.png',
    },
    {
      'title': 'نوق حليب جمل طويل الأجل بالشوكولاتة',
      'image': 'assets/alternatives/product2.png',
    },
    {
      'title': 'نوق حليب جمل طويل الأجل بالشوكولاتة',
      'image': 'assets/alternatives/product3.png',
    },
    {
      'title': 'نوق حليب جمل طويل الأجل بالشوكولاتة',
      'image': 'assets/alternatives/product4.png',
    },
  ];

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
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFAF6E9),
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
                      'البدائل الآمنة',
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
                          color: Colors.black87,
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
                          color: Colors.black87,
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
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _alternatives.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = _alternatives[index];
                    return _buildAlternativeCard(
                      title: item['title']!,
                      imagePath: item['image']!,
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlternativeCard({
    required String title,
    required String imagePath,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF6E9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.image_outlined,
                    size: 40,
                    color: Color(0xFFD1D1D1),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.tajawal(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: kGrey900,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}