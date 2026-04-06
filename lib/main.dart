import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // ← added
import 'views/onboarding/splash_screen.dart';
import 'package:provider/provider.dart'; // 🔥 مهم
import 'controllers/scan_controller.dart'; // 🔥 مهم

final supabase = Supabase.instance.client; // ← added: global Supabase client accessor

void main() async { // ← added: async
  WidgetsFlutterBinding.ensureInitialized(); // ← added: required before any async setup

  await Supabase.initialize( // ← added: initialize Supabase before app starts
    url: 'https://itwukjsvoihnewnbmgso.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml0d3VranN2b2lobmV3bmJtZ3NvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU2MTk5NjEsImV4cCI6MjA4MTE5NTk2MX0.zXLxXDqBXwnghJWFi1WW1qHBRnS6-pKkK3bcV3avJOI',
  );

  runApp(
    ChangeNotifierProvider( // 🔥 هنا الحل
      create: (_) => ScanController(),
      child: const SafeBiteApp(),
    ),
  );
}

class SafeBiteApp extends StatelessWidget {
  const SafeBiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'SafeBite',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.tajawalTextTheme(),
      ),
      home: const SplashScreen(),
    );
  }
}