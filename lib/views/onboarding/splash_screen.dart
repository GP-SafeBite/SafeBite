import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:safebite/views/onboarding/get_started_screen.dart';
import 'package:safebite/views/home/home_screen.dart';
import '../../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 3));

    final loggedIn = await AuthService.isLoggedIn();

    if (!mounted) return;

    if (loggedIn) {
      Get.off(() => const HomeScreen());
    } else {
      Get.off(() => const GetStartedScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark; // [FIXED Dark Mode]

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: SvgPicture.asset(
          isDark
              ? 'assets/logo/logo_darkmode.svg' // [FIXED Dark Mode]
              : 'assets/logo/logo_lightmode.svg', // [FIXED Dark Mode]
          width: 250,
          height: 325,
        ),
      ),
    );
  }
}