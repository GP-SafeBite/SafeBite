import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:safebite/views/onboarding/get_started_screen.dart';
import 'package:safebite/views/home/home_screen.dart'; // 🔴 added
import '../../services/auth_service.dart'; // 🔴 added

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus(); // 🔴 changed: check login instead of just waiting
  }

  // 🔴 added: checks SQLite first then Supabase
  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 3));

    // 🔴 check if user is already logged in
    final loggedIn = await AuthService.isLoggedIn();

    if (!mounted) return;

    if (loggedIn) {
      // 🔴 user already logged in → go straight to Home
      Get.off(() => const HomeScreen());
    } else {
      // 🔴 not logged in → go to GetStarted
      Get.off(() => const GetStartedScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF6),
      body: Center(
        child: SvgPicture.asset(
          'assets/logo/logo_lightmode.svg',
          width: 250,
          height: 325,
        ),
      ),
    );
  }
}