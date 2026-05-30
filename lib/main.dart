import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'views/onboarding/splash_screen.dart';
import 'package:provider/provider.dart';
import 'controllers/scan_controller.dart';
import 'controllers/theme_controller.dart';

final supabase = Supabase.instance.client;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // [PERF] Disable runtime font fetching — font is bundled in assets/fonts/
  GoogleFonts.config.allowRuntimeFetching = false;

  FlutterError.onError = (FlutterErrorDetails details) {
    print('🔴 FLUTTER ERROR: ${details.exception}');
    print('🔴 STACK TRACE:\n${details.stack}');
    FlutterError.presentError(details);
  };

  await GetStorage.init();

  await Supabase.initialize(
    url: 'https://itwukjsvoihnewnbmgso.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml0d3VranN2b2lobmV3bmJtZ3NvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU2MTk5NjEsImV4cCI6MjA4MTE5NTk2MX0.zXLxXDqBXwnghJWFi1WW1qHBRnS6-pKkK3bcV3avJOI',
  );

  Get.put(ThemeController());

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
    final themeController = Get.find<ThemeController>();

    return Obx(() => GetMaterialApp(
      title: 'SafeBite',
      debugShowCheckedModeBanner: false,
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
      themeMode: themeController.themeMode,
      home: const SplashScreen(),
    ));
  }
}