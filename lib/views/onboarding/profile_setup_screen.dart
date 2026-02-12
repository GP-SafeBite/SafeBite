// lib/views/onboarding/profile_setup_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/custom_button.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  // قائمة الحساسيات المختارة
  final Set<String> _selectedAllergies = {};

  // قائمة كل الحساسيات - ✅ PNG بدل SVG + lowercase
  final List<Map<String, dynamic>> _allergies = [
    {'name': 'الحليب', 'icon': 'assets/allergies14/milk.png', 'id': 'milk'},
    {'name': 'البيض', 'icon': 'assets/allergies14/eggs.png', 'id': 'eggs'},
    {'name': 'القشريات', 'icon': 'assets/allergies14/crustaceans.png', 'id': 'crustaceans'},
    {'name': 'الحبوب (مثل الجلوتين)', 'icon': 'assets/allergies14/gluten.png', 'id': 'gluten'},
    {'name': 'السمك', 'icon': 'assets/allergies14/fish.png', 'id': 'fish'},
    {'name': 'فول الصويا', 'icon': 'assets/allergies14/soyabeans.png', 'id': 'soybeans'},
    {'name': 'الكرفس', 'icon': 'assets/allergies14/celery.png', 'id': 'celery'},
    {'name': 'الفول السوداني', 'icon': 'assets/allergies14/peanuts.png', 'id': 'peanuts'},
    {'name': 'المكسرات', 'icon': 'assets/allergies14/treenuts.png', 'id': 'treenuts'},
    {'name': 'الخردل', 'icon': 'assets/allergies14/mustard.png', 'id': 'mustard'},
    {'name': 'الترمس', 'icon': 'assets/allergies14/lupin.png', 'id': 'lupin'},
    {'name': 'الرخويات', 'icon': 'assets/allergies14/mollusks.png', 'id': 'mollusks'},
    {'name': 'بذورالسمسم', 'icon': 'assets/allergies14/sesame.png', 'id': 'sesame'},
    {'name': 'الكبريتيت', 'icon': 'assets/allergies14/sulfur.png', 'id': 'sulfur'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF6),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),

            // العنوان
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'أخبرنا عن حساسيتك الغذائية',
                textAlign: TextAlign.center,
                style: GoogleFonts.tajawal(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // النص الفرعي
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'هذا يساعدنا في حمايتك من أي خطر!',
                textAlign: TextAlign.center,
                style: GoogleFonts.tajawal(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFFB3B3B3),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // عنوان القسم
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'اختر مسببات الحساسية لديك:',
                  style: GoogleFonts.tajawal(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // قائمة الحساسيات
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.end,
                  children: _allergies.map((allergy) {
                    final isSelected = _selectedAllergies.contains(allergy['id']);
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedAllergies.remove(allergy['id']);
                          } else {
                            _selectedAllergies.add(allergy['id']);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? const Color(0xFFE8F5E9)
                              : const Color(0xFFFAF6E9),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isSelected 
                                ? const Color(0xFF9CCB7A) 
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              allergy['name'],
                              style: GoogleFonts.tajawal(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // ✅ استخدام PNG
                            Image.asset(
                              allergy['icon'],
                              width: 20,
                              height: 20,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                debugPrint('❌ Error loading: ${allergy['icon']}');
                                return const Icon(
                                  Icons.error_outline,
                                  size: 20,
                                  color: Colors.red,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // زر المتابعة
            Padding(
              padding: const EdgeInsets.all(24),
              child: CustomButton(
                text: 'متابعة',
                onTap: () {
                  // TODO: هنا تنتقل للصفحة التالية
                  debugPrint('Selected allergies: $_selectedAllergies');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}