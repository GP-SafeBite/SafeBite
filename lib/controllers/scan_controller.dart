// Scan Controller - Coordinate product scan workflow and expose result state to the UI

import 'dart:io';
import 'package:flutter/foundation.dart';
import '../services/scan_service.dart';
import '../services/alternatives_service.dart';

class ScanController extends ChangeNotifier {
  bool _isLoading = false;
  Map<String, dynamic>? _result;
  String? _error;

  bool get isLoading => _isLoading;
  Map<String, dynamic>? get result => _result;
  String? get error => _error;

  // Analyze a product image and update state with allergen detection results
  Future<void> analyzeImage(File imageFile, String userId, {String productName = 'منتج من صورة'}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final bytes = await imageFile.readAsBytes();

      final scanResult = await ScanService.scanFromImage(
        imageBytes: bytes,
        userId: userId,
        productName: productName,
      );

      if (!scanResult.success) throw Exception(scanResult.message);

      final data = scanResult.data as ProductScanData;

      _result = {
        "ingredients": data.ingredients,
        "allergens": data.detectedAllergens,
        "allergen_types": data.detectedAllergenTypes,
        "llm_alternatives": data.llmSuggestedAlternatives,
        "llm_raw_alternatives": data.llmRawAlternatives,
        "product_type_ar": data.productTypeAr,
        "is_safe": data.safetyStatus == 'safe',
        "local_image_path": data.localImagePath ?? '',
        "remote_image_url": data.remoteImageUrl ?? '',
        "product_name": data.productName,
        // Include pre-fetched alternatives to avoid a second async call in the result screen
        "merged_alternatives": data.mergedAlternatives,
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

  // Reset scan result and error state before starting a new scan
  void clearResult() {
    _result = null;
    _error = null;
    notifyListeners();
  }
}