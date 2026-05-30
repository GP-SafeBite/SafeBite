import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safebite/views/authentication/login_screen.dart';
import 'package:safebite/views/authentication/register_screen.dart';
import '../../widgets/custom_button.dart';

class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark; // [FIXED Dark Mode]

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),

            SvgPicture.asset(
              isDark
                  ? 'assets/logo/logo_darkmode.svg'   // [FIXED Dark Mode]
                  : 'assets/logo/logo_lightmode.svg',
              width: 180,
            ),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'لقمة آمنة جاهز لحمايتك — ابدأ الآن أو سجل دخولك',
                textAlign: TextAlign.center,
                style: GoogleFonts.tajawal(
                  fontSize: 16,
                  color: const Color(0xFF9E9E9E),
                ),
              ),
            ),

            const SizedBox(height: 40),

            CustomButton(
              text: 'تسجيل الدخول',
              onTap: () => Get.to(() => const LoginScreen()),
            ),

            const SizedBox(height: 16),

            CustomButton(
              text: 'إنشاء حساب',
              onTap: () => Get.to(() => const RegisterScreen()),
            ),

            const Spacer(),
          ],
        ),
      ),
    );
  }
}