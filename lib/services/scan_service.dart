// Scan.service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/local_db.dart';
import 'profile_service.dart';
import 'gemini_service.dart';

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

  final List<String> hiddenSources;        // 🔥 جديد
  final List<String> warningStatements;    // 🔥 جديد

  final String safetyStatus;

  ProductScanData({
    required this.productName,
    required this.barcode,
    required this.imageUrl,
    required this.ingredients,
    required this.detectedAllergens,
    required this.hiddenSources,        // 🔥
    required this.warningStatements,    // 🔥
    required this.safetyStatus,
  });
}

class ScanService {
  static final _supabase = Supabase.instance.client;

  // ===================================================
  // 📸 MAIN FUNCTION: SCAN FROM IMAGE ONLY (Gemini)
  // ===================================================
  static Future<ScanResult> scanFromImage({
    required Uint8List imageBytes,
    required String userId,
  }) async {
    try {
      // 🤖 1. قراءة الصورة باستخدام Gemini
      final gemini = GeminiService();

      final aiResult =
          await gemini.analyzeProductImage(imageBytes);

// 🧠 اطبع رد Gemini
print("🧠 AI RESULT: $aiResult");

//
final rawAllergens = aiResult["detected_allergens"] ?? [];

final List<String> detectedAllergens = [];

for (final item in rawAllergens) {
  if (item is Map<String, dynamic>) {
    final ingredients =
        item["ingredients"] ?? item["components"] ?? [];

    for (final ing in ingredients) {
      detectedAllergens.add(ing.toString());
    }
  }
}

print("✅ Extracted Allergens: $detectedAllergens");

final rawHidden = aiResult["hidden_sources"] ?? [];

final List<String> hiddenSources = [];

for (final item in rawHidden) {
  if (item is Map<String, dynamic>) {
    final source = item["source"];
    if (source != null) {
      hiddenSources.add(source.toString());
    }
  }
}

final List<String> warningStatements =
    List<String>.from(aiResult["warning_statements"] ?? []);

    if (detectedAllergens.isEmpty &&
    hiddenSources.isEmpty &&
    warningStatements.isEmpty) {
  return ScanResult(
    success: false,
    message: "ما تم التعرف على المكونات",
  );
}


      // 👤 2. جلب حساسية المستخدم
      final userAllergyIds =
          await LocalDB.getUserAllergies(userId: userId);

      final userAllergyStrings = userAllergyIds
          .map((id) => ProfileService.allergyReverseMap[id])
          .where((id) => id != null)
          .cast<String>()
          .toSet();

final List<String> userMatchedAllergens = [];

for (final allergyId in userAllergyStrings) {
  final keywords = _allergyKeywords[allergyId] ?? [];

  for (final allergen in detectedAllergens) {
    final lowerAllergen = allergen.toLowerCase();

    for (final keyword in keywords) {
      if (lowerAllergen.contains(keyword)) {
        if (!userMatchedAllergens.contains(allergen)) {
          userMatchedAllergens.add(allergen);
        }
        break;
      }
    }
  }
}

      final safetyStatus =
          userMatchedAllergens.isEmpty ? 'safe' : 'unsafe';

      // 📦 4. تجهيز البيانات
      final scanData = ProductScanData(
  productName: "منتج من صورة",
  barcode: '',
  imageUrl: '',
  ingredients: detectedAllergens,
  detectedAllergens: userMatchedAllergens,
  hiddenSources: hiddenSources,            // 🔥
  warningStatements: warningStatements,    // 🔥
  safetyStatus: safetyStatus,
);
      // 💾 5. حفظ في Supabase + SQLite
      await _saveScanToHistory(
        userId: userId,
        scanData: scanData,
      );

      return ScanResult(
        success: true,
        message: safetyStatus == 'safe'
            ? 'المنتج آمن'
            : 'المنتج غير آمن',
        data: scanData,
      );

    } catch (e) {
      print("🔥 ERROR: $e"); // 👈 أضف هذا
      return ScanResult(
        success: false,
        message: "فشل تحليل الصورة",
      );
    }
  }

// ===================================================
// 📜 GET SCAN HISTORY
// ===================================================
static Future<ScanResult> getScanHistory({
  required String userId,
}) async {
  try {
    final data = await _supabase
        .from('scanhistory')
        .select()
        .eq('user_id', userId)
        .order('scan_date', ascending: false);

    return ScanResult(
      success: true,
      message: 'تم جلب السجل',
      data: data,
    );
  } catch (e) {
    return ScanResult(
      success: false,
      message: 'فشل جلب السجل',
    );
  }
}

  // ===================================================
  // 💾 SAVE HISTORY
  // ===================================================
  static Future<void> _saveScanToHistory({
    required String userId,
    required ProductScanData scanData,
  }) async {
    try {
      final foundAllergensJson =
          jsonEncode(scanData.detectedAllergens);

      await _supabase.from('scanhistory').insert({
        'user_id': userId,
        'product_id': 'image_${DateTime.now().millisecondsSinceEpoch}',
        'product_name': scanData.productName,
        'product_image_url': scanData.imageUrl,
        'found_allergens': foundAllergensJson,
        'safety_status': scanData.safetyStatus,
        'scan_date': DateTime.now().toIso8601String(),
      });

      await LocalDB.saveScanHistory(
        userId: userId,
        productId: 'image_${DateTime.now().millisecondsSinceEpoch}',
        productName: scanData.productName,
        productImageUrl: scanData.imageUrl,
        foundAllergens: foundAllergensJson,
        safetyStatus: scanData.safetyStatus,
      );
    } catch (e) {
      print('⚠️ History save failed: $e');
    }
  }

  // ===================================================
  // 🔍 ALLERGY KEYWORDS
  // ===================================================
  static const Map<String, List<String>> _allergyKeywords = {
  'milk': [
    'milk', 'dairy', 'lactose', 'whey', 'casein',
    'حليب', 'لبن', 'بودرة حليب', 'مصل الحليب', 'كازين'
  ],

  'eggs': [
    'egg', 'eggs', 'albumin',
    'بيض'
  ],

  'gluten': [
    'wheat', 'gluten', 'barley', 'rye', 'flour',
    'قمح', 'دقيق', 'جلوتين', 'شعير'
  ],

  'fish': ['fish', 'salmon', 'tuna'],

  'soybeans': [
    'soy', 'soya',
    'صويا', 'ليسيثين', 'فول الصويا'
  ],

  'treenuts': [
    'almond', 'cashew', 'walnut',
    'لوز', 'كاجو', 'جوز', 'بندق'
  ],

  'peanuts': [
    'peanut',
    'فول سوداني'
  ],

  'sesame': [
    'sesame', 'tahini',
    'سمسم', 'طحينة'
  ],
};

  // ===================================================
  // 🌍 ARABIC NAMES
  // ===================================================
  static const Map<String, String> _allergyArabicNames = {
    'milk': 'الحليب',
    'eggs': 'البيض',
    'gluten': 'الجلوتين',
    'fish': 'السمك',
    'peanuts': 'الفول السوداني',
    'soybeans': 'الصويا',
    'treenuts': 'المكسرات',
    'sesame': 'السمسم',
  };
}