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
  final String safetyStatus;

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

// 🔥 خذ أي نوع رد ممكن
final ingredientsText =
    (aiResult["ingredients_text"] ??
     aiResult["text"] ??
     aiResult["result"] ??
     aiResult.toString())
    .toLowerCase();

// تحقق
if (ingredientsText.isEmpty || ingredientsText == "{}") {
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

      // ⚠️ 3. تحليل الحساسية
      final List<String> detectedAllergens = [];

      for (final allergyId in userAllergyStrings) {
        final keywords = _allergyKeywords[allergyId] ?? [];

        for (final keyword in keywords) {
          if (ingredientsText.contains(keyword)) {
            final arabicName =
                _allergyArabicNames[allergyId] ?? allergyId;

            if (!detectedAllergens.contains(arabicName)) {
              detectedAllergens.add(arabicName);
            }
            break;
          }
        }
      }

      final safetyStatus =
          detectedAllergens.isEmpty ? 'safe' : 'unsafe';

      // 📦 4. تجهيز البيانات
      final scanData = ProductScanData(
        productName: "منتج من صورة",
        barcode: '',
        imageUrl: '',
        ingredients: ingredientsText.split(','),
        detectedAllergens: detectedAllergens,
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
    'milk': ['milk', 'dairy', 'lactose', 'whey', 'casein'],
    'eggs': ['egg', 'eggs', 'albumin'],
    'gluten': ['wheat', 'gluten', 'barley', 'rye', 'flour'],
    'fish': ['fish', 'salmon', 'tuna'],
    'peanuts': ['peanut'],
    'soybeans': ['soy', 'soya'],
    'treenuts': ['almond', 'cashew', 'walnut'],
    'sesame': ['sesame', 'tahini'],
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