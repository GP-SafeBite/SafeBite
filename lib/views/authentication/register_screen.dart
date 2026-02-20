import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/custom_text_field.dart';
import '../../services/auth_service.dart'; // 🔴 added
import 'login_screen.dart';
import 'verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

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

  // 🔴 changed: now async and calls AuthService.register()
  void _goToVerification() async {
    final name = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // 🔴 added: show loading spinner while waiting
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    // 🔴 added: call AuthService instead of just navigating
    final result = await AuthService.register(
      name: name,
      email: email,
      password: password,
    );

    // 🔴 added: hide loading spinner
    if (mounted) Navigator.of(context).pop();
    if (!mounted) return;

    if (result.success) {
      // 🔴 added: go to OTP screen only if registration succeeded
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VerificationScreen(email: email),
        ),
      );
    } else {
      // 🔴 added: show error from AuthService (wrong email, already exists etc)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message, style: GoogleFonts.tajawal()),
        ),
      );
    }
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
                    onPressed: _goToVerification,
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
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()),
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