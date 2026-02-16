import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/custom_text_field.dart';
import 'login_screen.dart';
import 'verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controllers
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Colors
  static const Color kPrimary = Color(0xFFA0C878);
  static const Color kBackground = Color(0xFFFFFDF6);
  static const Color kFieldBg = Color(0xFFFAF6E9);
  static const Color kGrey900 = Color(0xFF818898);
  static const Color kGrey400 = Color(0xFFB3B3B3);
  static const Color kGrey300 = Color(0xFFD1D1D1);

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _goToVerification() {
    final email = _emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فضلاً أدخل بريد إلكتروني صحيح')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VerificationScreen(email: email),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: kBackground,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),

                Text(
                  'إنشاء حساب جديد',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.tajawal(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 32),

                Text(
                  'الاسم الكامل',
                  textAlign: TextAlign.right,
                  style: GoogleFonts.tajawal(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: kGrey900,
                  ),
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  hint: 'أحمد',
                  controller: _fullNameController,
                  fieldBg: kFieldBg,
                  grey900: kGrey900,
                  grey300: kGrey300,
                ),

                const SizedBox(height: 20),

                Text(
                  'البريد الإلكتروني',
                  textAlign: TextAlign.right,
                  style: GoogleFonts.tajawal(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: kGrey900,
                  ),
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  hint: 'aaronramsdale@gmail.com',
                  controller: _emailController,
                  fieldBg: kFieldBg,
                  grey900: kGrey900,
                  grey300: kGrey300,
                ),

                const SizedBox(height: 20),

                Text(
                  'كلمة المرور',
                  textAlign: TextAlign.right,
                  style: GoogleFonts.tajawal(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: kGrey900,
                  ),
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  hint: '************',
                  controller: _passwordController,
                  isPassword: true,
                  fieldBg: kFieldBg,
                  grey900: kGrey900,
                  grey300: kGrey300,
                ),

                const SizedBox(height: 28),

                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _goToVerification, // ✅ الربط هنا
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'إنشاء حساب',
                      style: GoogleFonts.tajawal(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'لديك حساب بالفعل؟ ',
                      style: GoogleFonts.tajawal(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: kGrey400,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      child: Text(
                        'سجل دخولك',
                        style: GoogleFonts.tajawal(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: kPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
