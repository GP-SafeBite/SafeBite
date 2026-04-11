// lib/views/profile/about_app_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart'; // ✅ correct
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart'; // ✅ أضفته

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  static const Color kPrimary = Color(0xFF9CCB7A);
  static const Color kBackground = Color(0xFFFFFDF6);
  static const Color kFieldBg = Color(0xFFFAF6E9);
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
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // ========== HEADER ==========
                      Row(
                        children: [
                          // زر الرجوع (على اليمين)
                          GestureDetector(
                            onTap: () {
                              Get.back();
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: kFieldBg,
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
                          // العنوان
                          Text(
                            'حول التطبيق',
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

                      const SizedBox(height: 40),

                      // ========== شعار التطبيق ==========
                      SvgPicture.asset(
                        'assets/Logo/Logo_LightMode.svg', // ✅ SVG
                        width: 200,
                        height: 200,
                      ),

                      const SizedBox(height: 16),

                      // ========== الإصدار ==========
                      Text(
                        'الإصدار 1.0.0',
                        style: GoogleFonts.tajawal(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: kGrey900,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ========== نبذة عن التطبيق ==========
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'SafeBite هو تطبيق متخصص في الكشف عن مسببات الحساسية الغذائية، يساعد الأفراد الذين يعانون من حساسية تجاه أنواع معينة من الأطعمة. يوفر التطبيق فحصاً ذكياً وسريعاً للمنتجات الغذائية من خلال مسح الباركود أو تصوير المكونات.\n\nيمكن للمستخدمين إنشاء ملف شخصي يحدد أنواع الحساسية من بين 14 نوعاً شائعاً، ويحصلون على تقرير واضح يوضح إذا كان المنتج آمناً أو يحتوي على مكونات خطرة، مع إمكانية اقتراح بدائل آمنة ومحتوى تعليمي موثوق.',
                          style: GoogleFonts.tajawal(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: kGrey900,
                            height: 1.8,
                          ),
                          textAlign: TextAlign.justify,
                        ),
                      ),

                      const SizedBox(height: 80),
                      // ========== حقوق النشر ==========
                      Text(
                        '© 2025 SafeBite',
                        style: GoogleFonts.tajawal(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: kGrey900,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        'جميع الحقوق محفوظة',
                        style: GoogleFonts.tajawal(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: kGrey900,
                        ),
                      ),

                      const SizedBox(height: 20),
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