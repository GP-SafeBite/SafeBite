import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_svg/flutter_svg.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    
    // ⏰ بعد 3 ثواني، روح للشاشة التالية
    Timer(const Duration(seconds: 3), () {
      // ✅ تحقق إذا الـ widget لسه موجود قبل التنقل
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/language');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF6),
      
      body: Center(
        child: SvgPicture.asset(
          'assets/Logo/Logo_LightMode.svg',
          width: 200,
          height: 200,
        ),
      ),
    );
  }
}