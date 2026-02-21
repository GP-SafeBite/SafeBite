// lib/views/profile/edit_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:get_x/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/custom_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const Color kPrimary = Color(0xFF9CCB7A);
  static const Color kBackground = Color(0xFFFFFDF6);
  static const Color kFieldBg = Color(0xFFFAF6E9);
  static const Color kGrey900 = Color(0xFF818898);

  final TextEditingController _nameController = TextEditingController(text: 'أحمد');
  final TextEditingController _emailController = TextEditingController(text: 'aaronramsdale@gmail.com');

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

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
                          // زر الرجوع (على اليمين) ✅
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
                                Icons.arrow_back, // ✅ سهم لليمين
                                color: Colors.black,
                                size: 20,
                              ),
                            ),
                          ),
                          const Spacer(),
                          // العنوان
                          Text(
                            'تعديل الملف الشخصي',
                            style: GoogleFonts.tajawal(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          const Spacer(),
                          const SizedBox(width: 40), // للتوازن
                        ],
                      ),

                      const SizedBox(height: 40),

                      // ========== صورة البروفايل ==========
                      Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFB3D9E8),
                            ),
                            child: const Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.white,
                            ),
                          ),
                          // زر التعديل
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () {
                                // TODO: pick image
                              },
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: kPrimary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),

                      // ========== الاسم الكامل ==========
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'الاسم الكامل',
                          style: GoogleFonts.tajawal(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      Container(
                        decoration: BoxDecoration(
                          color: kFieldBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: _nameController,
                          textAlign: TextAlign.right,
                          style: GoogleFonts.tajawal(
                            fontSize: 15,
                            color: kGrey900,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ========== البريد الالكتروني ==========
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'البريد الالكتروني',
                          style: GoogleFonts.tajawal(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      Container(
                        decoration: BoxDecoration(
                          color: kFieldBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: _emailController,
                          textAlign: TextAlign.right, // ✅ محاذاة لليمين
                          style: GoogleFonts.tajawal(
                            fontSize: 15,
                            color: kGrey900,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ========== زر حفظ التغييرات ==========
              Padding(
                padding: const EdgeInsets.all(20),
                child: CustomButton(
                  text: 'حفظ التغييرات',
                  onTap: () {
                    // TODO: save changes
                    debugPrint('Name: ${_nameController.text}');
                    debugPrint('Email: ${_emailController.text}');
                    Get.back();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}