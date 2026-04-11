// Scan.controller.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../services/scan_service.dart';

class ScanController extends ChangeNotifier {

  bool _isLoading = false;
  Map<String, dynamic>? _result;
  String? _error;

  bool get isLoading => _isLoading;
  Map<String, dynamic>? get result => _result;
  String? get error => _error;

  // ===================================================
  // 📸 تحليل الصورة (Gemini + Allergy Detection)
  // ===================================================
  Future<void> analyzeImage(File imageFile, String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print("📸 Reading image...");
      final bytes = await imageFile.readAsBytes();

      // 🔥 استدعاء ScanService (مو Gemini مباشرة)
      final scanResult = await ScanService.scanFromImage(
        imageBytes: bytes,
        userId: userId,
      );

      if (!scanResult.success) {
        throw Exception(scanResult.message);
      }

      final data = scanResult.data;

      // 📦 النتيجة النهائية للـ UI
_result = {
  "ingredients": data.ingredients,
  "allergens": data.detectedAllergens,
  "hidden_sources": data.hiddenSources,
  "warnings": data.warningStatements,
  "is_safe": data.safetyStatus == 'safe',
"is_unknown": data.safetyStatus == 'unknown', // 🔥 جديد
};

      print("✅ Final Result: $_result");

    } catch (e) {
      print("🔥 Error: $e");
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ===================================================
  // 🧹 تنظيف النتائج
  // ===================================================
  void clearResult() {
    _result = null;
    _error = null;
    notifyListeners();
  }
}