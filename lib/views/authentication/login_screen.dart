import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/custom_text_field.dart';
import '../onboarding/profile_setup_screen.dart';
import 'register_screen.dart';
import 'verification_screen.dart';
import '../../services/auth_service.dart'; // 🔴 added
import '../home/home_screen.dart'; // 🔴 added

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const Color kPrimary = Color(0xFFA0C878);
  static const Color kBg = Color(0xFFFFFDF6);
  static const Color kField = Color(0xFFFAF6E9);
  static const Color kGrey900 = Color(0xFF818898);
  static const Color kGrey400 = Color(0xFFB3B3B3);
  static const Color kGrey300 = Color(0xFFD1D1D1);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _goToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  // 🔴 fixed: removed duplicate SnackBar, simplified function
  void _goToVerification() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VerificationScreen(email: _emailController.text.trim()),
      ),
    );
  }

  // 🔴 changed: now async and calls AuthService.login()
  void _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('الرجاء ملء جميع الحقول', style: GoogleFonts.tajawal()),
        ),
      );
      return;
    }

    // 🔴 added: show loading spinner while waiting
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    // 🔴 added: call AuthService instead of TODO
    final result = await AuthService.login(
      email: email,
      password: password,
    );

    // 🔴 added: hide loading spinner
    if (mounted) Navigator.of(context).pop();
    if (!mounted) return;

    if (result.success) {
      // 🔴 added: go to Home on successful login
      Get.offAll(() => const HomeScreen());
    } else if (result.data != null &&
        result.data['needsVerification'] == true) {
      // 🔴 added: user registered but never verified OTP
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VerificationScreen(email: email),
        ),
      );
    } else {
      // 🔴 added: show error message from AuthService
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
        backgroundColor: LoginScreen.kBg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),

                Text(
                  'مرحباً بعودتك! 👋',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.tajawal(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 40),

                Text(
                  'البريد الإلكتروني',
                  textAlign: TextAlign.right,
                  style: GoogleFonts.tajawal(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: LoginScreen.kGrey900,
                  ),
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  hint: 'أدخل بريدك الإلكتروني',
                  controller: _emailController,
                  fieldBg: LoginScreen.kField,
                  grey900: LoginScreen.kGrey900,
                  grey300: LoginScreen.kGrey300,
                ),

                const SizedBox(height: 20),

                Text(
                  'كلمة المرور',
                  textAlign: TextAlign.right,
                  style: GoogleFonts.tajawal(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: LoginScreen.kGrey900,
                  ),
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  hint: 'أدخل كلمة المرور',
                  controller: _passwordController,
                  isPassword: true,
                  fieldBg: LoginScreen.kField,
                  grey900: LoginScreen.kGrey900,
                  grey300: LoginScreen.kGrey300,
                ),

                const SizedBox(height: 14),

                Align(
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: _goToVerification,
                    child: Text(
                      'تسجيل الدخول برمز تحقق',
                      style: GoogleFonts.tajawal(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: LoginScreen.kPrimary,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LoginScreen.kPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'تسجيل الدخول',
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
                      'ليس لديك حساب؟ ',
                      style: GoogleFonts.tajawal(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: LoginScreen.kGrey400,
                      ),
                    ),
                    InkWell(
                      onTap: _goToRegister,
                      child: Text(
                        'سجل الآن',
                        style: GoogleFonts.tajawal(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: LoginScreen.kPrimary,
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