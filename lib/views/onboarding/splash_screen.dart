// lib/app/modules/splash/splash_view.dart
import 'package:flutter/material.dart';
import 'package:get_x/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:safebite/views/onboarding/get_started_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // ⏰ بعد 3 ثواني، روح لـ GetStarted
    Future.delayed(const Duration(seconds: 3), () {
      Get.off(() => const GetStartedScreen());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF6),

      body: Center(
        child: SvgPicture.asset(
          'assets/Logo/Logo_LightMode.svg',
          width: 250,
          height: 325,
        ),
      ),
    );
  }
}
