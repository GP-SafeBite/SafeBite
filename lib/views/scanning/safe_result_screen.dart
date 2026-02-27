import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SafeResultScreen extends StatelessWidget {
  final String productName;
  final String? barcode;
  final String? imageUrl; // 🔴 added

  const SafeResultScreen({
    super.key,
    this.productName = 'أوريو OREO',
    this.barcode,
    this.imageUrl, // 🔴 added
  });

  static const Color kPrimary = Color(0xFF9CCB7A);
  static const Color kBackground = Color(0xFFFFFDF6);
  static const Color kGrey900 = Color(0xFF818898);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: kBackground,
        body: SafeArea(
          child: Column(
            children: [
              // ========== HEADER ==========
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
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
                      'مسح الباركود',
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

              // ========== صورة المنتج ==========
              // 🔴 changed: shows real product image from Open Food Facts
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
                          // 🔴 show real image if available
                          ? Image.network(
                              imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(
                                    Icons.image_not_supported_outlined,
                                    size: 80,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              },
                            )
                          // 🔴 fallback if no image
                          : const Center(
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                size: 80,
                                color: Colors.grey,
                              ),
                            ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ========== النتيجة ==========
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/icone/safe.png',
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 32,
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'المنتج ',
                          style: GoogleFonts.tajawal(
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                            color: kGrey900,
                          ),
                        ),
                        TextSpan(
                          text: 'آمن!',
                          style: GoogleFonts.tajawal(
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                            color: kPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ========== اسم المنتج ==========
              Text(
                'اسم المنتج: $productName',
                style: GoogleFonts.tajawal(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: kGrey900,
                ),
              ),

              const Spacer(),

              // ========== زر فحص منتج آخر ==========
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                    ),
                    child: Text(
                      'فحص منتج آخر',
                      style: GoogleFonts.tajawal(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // ========== BOTTOM NAVIGATION ==========
              Container(
                height: 70,
                decoration: const BoxDecoration(
                  color: kBackground,
                ),
                child: Row(
                  children: [
                    _buildNavItem(Icons.home, 'الرئيسية', true),
                    _buildNavItem(Icons.history, 'السجل', false),
                    _buildNavItem(
                        Icons.description_outlined, 'محتوى توعوي', false),
                    _buildNavItem(
                        Icons.person_outline, 'الملف الشخصي', false),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return Expanded(
      child: GestureDetector(
        onTap: () {},
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? kPrimary : kGrey900,
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.tajawal(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? kPrimary : kGrey900,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}