import 'package:flutter/material.dart';
import 'package:get_x/get.dart';
import 'views/onboarding/splash_screen.dart';

void main() {
  runApp(const SafeBiteApp());
}

class SafeBiteApp extends StatelessWidget {
  const SafeBiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(  
      title: 'SafeBite',
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(), 
    );
  }
}