import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'views/onboarding/splash_screen.dart';
import 'package:provider/provider.dart';
import 'controllers/scan_controller.dart';

final supabase = Supabase.instance.client;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Catch ALL flutter errors with full stack trace
  FlutterError.onError = (FlutterErrorDetails details) {
    print('🔴 FLUTTER ERROR: ${details.exception}');
    print('🔴 STACK TRACE:\n${details.stack}');
    FlutterError.presentError(details); // still show red screen
  };

  await Supabase.initialize(
    url: 'https://itwukjsvoihnewnbmgso.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml0d3VranN2b2lobmV3bmJtZ3NvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU2MTk5NjEsImV4cCI6MjA4MTE5NTk2MX0.zXLxXDqBXwnghJWFi1WW1qHBRnS6-pKkK3bcV3avJOI',
  );

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