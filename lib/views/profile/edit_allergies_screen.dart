import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart'; // 🔴 added
import '../../services/profile_service.dart'; // 🔴 added
import '../../widgets/custom_button.dart';

class EditAllergiesScreen extends StatefulWidget {
  const EditAllergiesScreen({super.key});

  @override
  State<EditAllergiesScreen> createState() => _EditAllergiesScreenState();
}

class _EditAllergiesScreenState extends State<EditAllergiesScreen> {
  Set<String> _selectedAllergies = {};
  bool _isLoading = true; // 🔴 added: true while loading existing selections

  final List<Map<String, dynamic>> _allergies = [
    {'name': 'الحليب', 'icon': 'Assets/allergies14/milk.png', 'id': 'milk'},
    {'name': 'البيض', 'icon': 'Assets/allergies14/eggs.png', 'id': 'eggs'},
    {'name': 'القشريات', 'icon': 'Assets/allergies14/crustaceans.png', 'id': 'crustaceans'},
    {'name': 'الحبوب (مثل الجلوتين)', 'icon': 'Assets/allergies14/gluten.png', 'id': 'gluten'},
    {'name': 'السمك', 'icon': 'Assets/allergies14/fish.png', 'id': 'fish'},
    {'name': 'فول الصويا', 'icon': 'Assets/allergies14/soyabeans.png', 'id': 'soybeans'},
    {'name': 'الكرفس', 'icon': 'Assets/allergies14/celery.png', 'id': 'celery'},
    {'name': 'الفول السوداني', 'icon': 'Assets/allergies14/peanuts.png', 'id': 'peanuts'},
    {'name': 'المكسرات', 'icon': 'Assets/allergies14/treenuts.png', 'id': 'treenuts'},
    {'name': 'الخردل', 'icon': 'Assets/allergies14/mustard.png', 'id': 'mustard'},
    {'name': 'الترمس', 'icon': 'Assets/allergies14/lupin.png', 'id': 'lupin'},
    {'name': 'الرخويات', 'icon': 'Assets/allergies14/mollusks.png', 'id': 'mollusks'},
    {'name': 'بذورالسمسم', 'icon': 'Assets/allergies14/sesame.png', 'id': 'sesame'},
    {'name': 'الكبريتيت', 'icon': 'Assets/allergies14/sulfur.png', 'id': 'sulfur'},
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingSelections(); // 🔴 added: load saved allergies when screen opens
  }

  // 🔴 added: load user's existing allergy selections
  Future<void> _loadExistingSelections() async {
    final user = await AuthService.getCurrentUser();
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    final result = await ProfileService.getUserAllergens(
      userId: user['user_id'],
    );

    if (mounted) {
      setState(() {
        if (result.success && result.data != null) {
          _selectedAllergies = result.data as Set<String>;
        }
        _isLoading = false;
      });
    }
  }

  // 🔴 added: save updated selections
  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);

    final user = await AuthService.getCurrentUser();
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    final result = await ProfileService.updateUserAllergens(
      userId: user['user_id'],
      selectedIds: _selectedAllergies,
    );

    setState(() => _isLoading = false);
    if (!mounted) return;

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ التغييرات بنجاح ✅')),
      );
      Get.back(); // 🔴 go back to profile screen
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF6),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFAF6E9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_forward,
                        color: Colors.black, size: 20),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
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
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 🔴 added: show spinner while loading existing selections
            _isLoading
                ? const Expanded(
                    child: Center(child: CircularProgressIndicator()))
                : Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.end,
                        children: _allergies.map((allergy) {
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
                                  Image.asset(
                                    allergy['icon'],
                                    width: 20,
                                    height: 20,
                                    fit: BoxFit.contain,
                                    errorBuilder:
                                        (context, error, stackTrace) {
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
              child: CustomButton(
                text: 'حفظ التغييرات', // 🔴 changed from متابعة
                onTap: _saveChanges, // 🔴 changed from TODO
              ),
            ),
          ],
        ),
      ),
    );
  }
}