import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../alternatives/alternatives_screen.dart';

class UnsafeResultScreen extends StatelessWidget {
  final String productName;
  final List<String> detectedAllergens;
  final List ingredients; // 🔥 جديد
  final String? imageUrl;

  const UnsafeResultScreen({
    super.key,
    required this.productName,
    required this.detectedAllergens,
    required this.ingredients, // 🔥 جديد
    this.imageUrl,
  });

  static const Color kPrimary = Color(0xFF9CCB7A);
  static const Color kBackground = Color(0xFFFFFDF6);
  static const Color kGrey900 = Color(0xFF818898);
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
                          decoration: const BoxDecoration(
                            color: Color(0xFFFAF6E9),
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

                const SizedBox(height: 32),

                // النتيجة
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cancel, color: Colors.red, size: 32),
                    const SizedBox(width: 8),
                    Text(
                      'المنتج غير آمن',
                      style: GoogleFonts.tajawal(
                        fontSize: 18,
                        color: kRed,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // اسم المنتج
                Text(
                  'اسم المنتج: $productName',
                  style: GoogleFonts.tajawal(fontSize: 15),
                ),

                const SizedBox(height: 20),

                // 🔥 المكونات
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
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ingredients.join(', '),
                        style: GoogleFonts.tajawal(fontSize: 14),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 🔥 مسببات الحساسية
                Column(
                  children: [
                    Text(
                      'مسببات الحساسية:',
                      style: GoogleFonts.tajawal(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...detectedAllergens.map(
                      (a) => Text("• $a",
                          style: GoogleFonts.tajawal(color: kRed)),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // الأزرار
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AlternativesScreen(
                                unsafeProductName: productName,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimary,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: Text(
                          'عرض البدائل الآمنة',
                          style: GoogleFonts.tajawal(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimary,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: Text(
                          'فحص منتج آخر',
                          style: GoogleFonts.tajawal(),
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