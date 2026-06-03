// Profile Setup - User allergen selection during registration
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safebite/views/home/home_screen.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../widgets/custom_button.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final Set<String> _selectedAllergies = {};
  bool _isLoading = false;

  // SFDA approved allergen list (14 categories)
  final List<Map<String, dynamic>> _allAllergies = [
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

  Future<void> _saveAndContinue() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final user = await AuthService.getCurrentUser();
    if (user == null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('خطأ: لم يتم العثور على المستخدم')),
      );
      return;
    }

    // Save selected allergens to Supabase
    final result = await ProfileService.saveUserAllergens(
      userId: user['user_id'],
      selectedIds: _selectedAllergies,
    );

    setState(() => _isLoading = false);
    if (!mounted) return;

    if (result.success) {
      Get.offAll(() => const HomeScreen());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color kBackground = Theme.of(context).scaffoldBackgroundColor;
    final Color kCardBg = Theme.of(context).cardColor;

    return Scaffold(
      backgroundColor: kBackground, 
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'أخبرنا عن حساسيتك الغذائية',
                textAlign: TextAlign.center,
                style: GoogleFonts.tajawal(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface, 
                ),
              ),
            ),
            const SizedBox(height: 8),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'اختر مسببات الحساسية لديك:',
                  style: GoogleFonts.tajawal(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface, 
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.end,
                  children: _allAllergies.map((allergy) {
                    final isSelected =
                        _selectedAllergies.contains(allergy['id']);
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
                              : kCardBg, 
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
                                color: Theme.of(context).colorScheme.onSurface, 
                              ),
                            ),
                            const SizedBox(width: 8),
                            Image.asset(
                              allergy['icon'],
                              width: 20,
                              height: 20,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.error_outline,
                                    size: 20, color: Colors.red);
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
            Padding(
              padding: const EdgeInsets.all(24),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : CustomButton(
                      text: 'متابعة',
                      onTap: _saveAndContinue,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}