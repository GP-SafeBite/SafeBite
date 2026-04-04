import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/local_db.dart';
import 'profile_service.dart';

class ScanResult {
  final bool success;
  final String message;
  final dynamic data;

  ScanResult({
    required this.success,
    required this.message,
    this.data,
  });
}

class ProductScanData {
  final String productName;
  final String barcode;
  final String imageUrl;
  final List<String> ingredients;
  final List<String> detectedAllergens;
  final String safetyStatus; // 'safe', 'unsafe', 'unknown'

  ProductScanData({
    required this.productName,
    required this.barcode,
    required this.imageUrl,
    required this.ingredients,
    required this.detectedAllergens,
    required this.safetyStatus,
  });
}

class ScanService {
  static final _supabase = Supabase.instance.client;

  // ──────────────────────────────────────────────
  // FETCH PRODUCT BY BARCODE
  // Calls Open Food Facts API (free, no key needed)
  // Returns product name, image, ingredients
  // ──────────────────────────────────────────────
  static Future<ScanResult> fetchProductByBarcode({
    required String barcode,
    required String userId,
  }) async {
    try {
      // 🔴 call Open Food Facts API
      final url = Uri.parse(
        'https://world.openfoodfacts.org/api/v0/product/$barcode.json',
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode != 200) {
        return ScanResult(
          success: false,
          message: 'فشل الاتصال بقاعدة بيانات المنتجات',
        );
      }

      final json = jsonDecode(response.body);

      // Product not found in Open Food Facts
      if (json['status'] == 0) {
        return ScanResult(
          success: false,
          message: 'المنتج غير موجود في قاعدة البيانات',
        );
      }

      final product = json['product'];

      // 🔴 extract product info
      final productName = product['product_name'] ??
          product['product_name_ar'] ??
          product['abbreviated_product_name'] ??
          'منتج غير معروف';

      final imageUrl = product['image_url'] ?? '';

      // 🔴 extract ingredients text
      final ingredientsText = (product['ingredients_text'] ??
              product['ingredients_text_ar'] ??
              product['ingredients_text_en'] ??
              '')
          .toString()
          .toLowerCase();

      // 🔴 get user's allergies from SQLite
      final userAllergyIds =
          await LocalDB.getUserAllergies(userId: userId);

      final userAllergyStrings = userAllergyIds
          .map((id) => ProfileService.allergyReverseMap[id])
          .where((id) => id != null)
          .cast<String>()
          .toSet();

      // 🔴 check ingredients against user allergies
      final detectedAllergens = await _checkAllergens(
        ingredientsText: ingredientsText,
        product: product,
        userAllergyIds: userAllergyStrings,
      );

      final safetyStatus =
          detectedAllergens.isEmpty ? 'safe' : 'unsafe';

      final scanData = ProductScanData(
        productName: productName,
        barcode: barcode,
        imageUrl: imageUrl,
        ingredients: [ingredientsText],
        detectedAllergens: detectedAllergens,
        safetyStatus: safetyStatus,
      );

      // 🔴 save scan to history
      await _saveScanToHistory(
        userId: userId,
        scanData: scanData,
      );

      return ScanResult(
        success: true,
        message: safetyStatus == 'safe' ? 'المنتج آمن' : 'المنتج غير آمن',
        data: scanData,
      );
    } catch (e) {
      return ScanResult(
        success: false,
        message: 'خطأ في الاتصال. تحقق من الإنترنت',
      );
    }
  }

  // ──────────────────────────────────────────────
  // CHECK INGREDIENTS TEXT
  // For scan_ingredients_screen (manual text input)
  // User types ingredients → we check against allergies
  // ──────────────────────────────────────────────
  static Future<ScanResult> checkIngredientsText({
    required String ingredientsText,
    required String userId,
    String productName = 'منتج مجهول',
  }) async {
    try {
      // 🔴 get user allergies
      final userAllergyIds =
          await LocalDB.getUserAllergies(userId: userId);

      final userAllergyStrings = userAllergyIds
          .map((id) => ProfileService.allergyReverseMap[id])
          .where((id) => id != null)
          .cast<String>()
          .toSet();

      // 🔴 check text against allergy keywords
      final detectedAllergens = _checkTextForAllergens(
        text: ingredientsText.toLowerCase(),
        userAllergyIds: userAllergyStrings,
      );

      final safetyStatus =
          detectedAllergens.isEmpty ? 'safe' : 'unsafe';

      final scanData = ProductScanData(
        productName: productName,
        barcode: '',
        imageUrl: '',
        ingredients: [ingredientsText],
        detectedAllergens: detectedAllergens,
        safetyStatus: safetyStatus,
      );

      // 🔴 save to history
      await _saveScanToHistory(
        userId: userId,
        scanData: scanData,
      );

      return ScanResult(
        success: true,
        message: safetyStatus == 'safe' ? 'المنتج آمن' : 'المنتج غير آمن',
        data: scanData,
      );
    } catch (e) {
      return ScanResult(
        success: false,
        message: 'خطأ في التحقق من المكونات',
      );
    }
  }

  // ──────────────────────────────────────────────
  // CHECK ALLERGENS
  // Compares product allergen tags + ingredients text
  // against user's selected allergies
  // ──────────────────────────────────────────────
  static Future<List<String>> _checkAllergens({
    required String ingredientsText,
    required Map<String, dynamic> product,
    required Set<String> userAllergyIds,
  }) async {
    final List<String> detected = [];

    // 🔴 Open Food Facts provides allergens_tags list
    final allergenTags =
        (product['allergens_tags'] as List<dynamic>? ?? [])
            .map((e) => e.toString().toLowerCase())
            .toList();

    for (final allergyId in userAllergyIds) {
      final keywords = _allergyKeywords[allergyId] ?? [];
      bool found = false;

      // Check allergen tags first (most reliable)
      for (final keyword in keywords) {
        if (allergenTags.any((tag) => tag.contains(keyword))) {
          found = true;
          break;
        }
      }

      // Also check ingredients text
      if (!found) {
        for (final keyword in keywords) {
          if (ingredientsText.contains(keyword)) {
            found = true;
            break;
          }
        }
      }

      if (found) {
        // 🔴 get Arabic name for display
        final arabicName = _allergyArabicNames[allergyId] ?? allergyId;
        detected.add(arabicName);
      }
    }

    return detected;
  }

  // ──────────────────────────────────────────────
  // CHECK TEXT FOR ALLERGENS
  // Used for manual ingredients text input
  // ──────────────────────────────────────────────
  static List<String> _checkTextForAllergens({
    required String text,
    required Set<String> userAllergyIds,
  }) {
    final List<String> detected = [];

    for (final allergyId in userAllergyIds) {
      final keywords = _allergyKeywords[allergyId] ?? [];
      for (final keyword in keywords) {
        if (text.contains(keyword)) {
          final arabicName = _allergyArabicNames[allergyId] ?? allergyId;
          if (!detected.contains(arabicName)) {
            detected.add(arabicName);
          }
          break;
        }
      }
    }

    return detected;
  }

  // ──────────────────────────────────────────────
  // SAVE SCAN TO HISTORY
  // Saves to both Supabase scanhistory and SQLite
  // ──────────────────────────────────────────────
  static Future<void> _saveScanToHistory({
    required String userId,
    required ProductScanData scanData,
  }) async {
    try {
      final foundAllergensJson =
          jsonEncode(scanData.detectedAllergens);

      // 🔴 save to Supabase
      await _supabase.from('scanhistory').insert({
        'user_id': userId,
        'product_id': scanData.barcode.isEmpty
            ? 'manual_${DateTime.now().millisecondsSinceEpoch}'
            : scanData.barcode,
        'product_name': scanData.productName,
        'product_image_url': scanData.imageUrl,
        'found_allergens': foundAllergensJson,
        'safety_status': scanData.safetyStatus,
        'scan_date': DateTime.now().toIso8601String(),
      });

      // 🔴 save to SQLite
      await LocalDB.saveScanHistory(
        userId: userId,
        productId: scanData.barcode.isEmpty
            ? 'manual_${DateTime.now().millisecondsSinceEpoch}'
            : scanData.barcode,
        productName: scanData.productName,
        productImageUrl: scanData.imageUrl,
        foundAllergens: foundAllergensJson,
        safetyStatus: scanData.safetyStatus,
      );
    } catch (e) {
      // 🔴 don't fail the scan if history save fails
      print('⚠️ History save failed: $e');
    }
  }

  // ──────────────────────────────────────────────
  // GET SCAN HISTORY
  // Returns user's scan history from SQLite
  // ──────────────────────────────────────────────
  static Future<ScanResult> getScanHistory({
    required String userId,
  }) async {
    try {
      final history = await LocalDB.getScanHistory(userId: userId);
      return ScanResult(
        success: true,
        message: 'تم تحميل السجل',
        data: history,
      );
    } catch (e) {
      return ScanResult(
        success: false,
        message: 'فشل تحميل السجل',
        data: [],
      );
    }
  }

  // ──────────────────────────────────────────────
  // KEYWORDS MAP
  // English keywords for each allergy
  // Used to search ingredients text
  // ──────────────────────────────────────────────
  static const Map<String, List<String>> _allergyKeywords = {
    'milk': ['milk', 'dairy', 'lactose', 'whey', 'casein', 'butter', 'cream', 'cheese', 'lacto'],
    'eggs': ['egg', 'eggs', 'albumin', 'mayonnaise', 'lecithin'],
    'gluten': ['wheat', 'gluten', 'barley', 'rye', 'oat', 'flour', 'starch'],
    'crustaceans': ['shrimp', 'crab', 'lobster', 'prawn', 'crustacean'],
    'fish': ['fish', 'salmon', 'tuna', 'cod', 'anchovy', 'sardine', 'tilapia'],
    'peanuts': ['peanut', 'groundnut', 'arachis'],
    'soybeans': ['soy', 'soya', 'tofu', 'edamame', 'miso'],
    'treenuts': ['almond', 'cashew', 'walnut', 'pistachio', 'hazelnut', 'pecan', 'nut'],
    'celery': ['celery', 'celeriac'],
    'mustard': ['mustard', 'sinapis'],
    'sesame': ['sesame', 'tahini', 'til', 'gingelly'],
    'sulfur': ['sulfur', 'sulphur', 'sulfite', 'sulphite', 'so2', 'e220', 'e221', 'e222', 'e223', 'e224'],
    'lupin': ['lupin', 'lupine', 'lupin flour'],
    'mollusks': ['mollusk', 'mollusc', 'squid', 'octopus', 'clam', 'oyster', 'mussel', 'scallop'],
  };

  // ──────────────────────────────────────────────
  // ARABIC NAMES MAP
  // For displaying detected allergens in Arabic
  // ──────────────────────────────────────────────
  static const Map<String, String> _allergyArabicNames = {
    'milk': 'الحليب',
    'eggs': 'البيض',
    'gluten': 'الحبوب (جلوتين)',
    'crustaceans': 'القشريات',
    'fish': 'السمك',
    'peanuts': 'الفول السوداني',
    'soybeans': 'فول الصويا',
    'treenuts': 'المكسرات',
    'celery': 'الكرفس',
    'mustard': 'الخردل',
    'sesame': 'بذور السمسم',
    'sulfur': 'الكبريتيت',
    'lupin': 'الترمس',
    'mollusks': 'الرخويات',
  };
}