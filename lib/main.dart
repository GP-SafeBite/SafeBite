import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart'; // ✅ [Added]
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'views/onboarding/splash_screen.dart';
import 'package:provider/provider.dart';
import 'controllers/scan_controller.dart';
import 'controllers/theme_controller.dart'; // ✅ [Added]

final supabase = Supabase.instance.client;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GetStorage.init(); // ✅ [Added]

  await Supabase.initialize(
    url: 'https://itwukjsvoihnewnbmgso.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml0d3VranN2b2lobmV3bmJtZ3NvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU2MTk5NjEsImV4cCI6MjA4MTE5NTk2MX0.zXLxXDqBXwnghJWFi1WW1qHBRnS6-pKkK3bcV3avJOI',
  );

  Get.put(ThemeController()); // ✅ [Added]

  runApp(
    ChangeNotifierProvider(
      create: (_) => ScanController(),
      child: const SafeBiteApp(),
    ),
  );
}

class SafeBiteApp extends StatelessWidget {
  const SafeBiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>(); // ✅ [Added]

    return Obx(() => GetMaterialApp( // ✅ [Added] Obx for reactive theme switching
      title: 'SafeBite',
      debugShowCheckedModeBanner: false,
      // ✅ [Added] Light theme
      theme: ThemeData(
        brightness: Brightness.light,
        textTheme: GoogleFonts.tajawalTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFFFFDF6),
        cardColor: const Color(0xFFFAF6E9),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF9CCB7A),
          brightness: Brightness.light,
        ),
      ),
      // ✅ [Added] Dark theme
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        textTheme: GoogleFonts.tajawalTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF9CCB7A),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: themeController.themeMode, // ✅ [Added]
      home: const SplashScreen(),
    ));
  }
}