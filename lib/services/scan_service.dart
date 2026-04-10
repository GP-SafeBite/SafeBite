import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/local_db.dart';
import 'profile_service.dart';
import 'gemini_service.dart';

class ScanResult {
  final bool success;
  final String message;
  final dynamic data;

  ScanResult({required this.success, required this.message, this.data});
}

class ProductScanData {
  final String productName;
  final List<String> ingredients;
  final List<String> detectedAllergens;
  final String safetyStatus;
  final String? localImagePath;

  ProductScanData({
    required this.productName,
    required this.ingredients,
    required this.detectedAllergens,
    required this.safetyStatus,
    this.localImagePath,
  });
}

class ScanService {
  static final _supabase = Supabase.instance.client;

  static Future<ScanResult> scanFromImage({
    required Uint8List imageBytes,
    required String userId,
    String productName = 'منتج من صورة',
  }) async {
    try {
      // 1. Save image locally
      final localImagePath = await _saveImageLocally(imageBytes);

      // 2. Analyze with Gemini
      final gemini = GeminiService();
      final aiResult = await gemini.analyzeProductImage(imageBytes);
      print("🧠 AI RESULT: $aiResult");

      // 3. Extract detected allergens from Gemini
// ✅ FIX - Extract ingredient strings from each allergen map
final List<String> geminiAllergens = [];

final rawAllergens = aiResult["detected_allergens"] ?? [];
for (final allergenGroup in rawAllergens) {
  if (allergenGroup is Map) {
    final ingredients = allergenGroup["ingredients"];
    if (ingredients is List) {
      for (final ingredient in ingredients) {
        if (ingredient is String && ingredient.trim().isNotEmpty) {
          geminiAllergens.add(ingredient.trim());
        }
      }
    }
  }
};

      // 4. Build ingredients list cleanly
      final List<String> ingredientsList = geminiAllergens.isNotEmpty
          ? geminiAllergens
          : [];

      final ingredientsText = ingredientsList.join(', ');

      if (ingredientsList.isEmpty) {
        return ScanResult(success: false, message: "ما تم التعرف على المكونات");
      }

      // 5. Get user allergies
      final userAllergyIds = await LocalDB.getUserAllergies(userId: userId);
      final userAllergyStrings = userAllergyIds
          .map((id) => ProfileService.allergyReverseMap[id])
          .whereType<String>()
          .toSet();

      // 6. Detect allergens by cross-referencing Gemini output with user allergies
      final List<String> detectedAllergens = [];

      for (final geminiAllergen in geminiAllergens) {
        final lower = geminiAllergen.toLowerCase();
        for (final userAllergy in userAllergyStrings) {
          final keywords = _allergyKeywords[userAllergy] ?? [];
          for (final keyword in keywords) {
            if (lower.contains(keyword)) {
              final arabicName = _allergyArabicNames[userAllergy] ?? userAllergy;
              if (!detectedAllergens.contains(arabicName)) {
                detectedAllergens.add(arabicName);
              }
              break;
            }
          }
        }
      }

      final safetyStatus = detectedAllergens.isEmpty ? 'safe' : 'unsafe';

      final scanData = ProductScanData(
        productName: productName,
        ingredients: ingredientsList,
        detectedAllergens: detectedAllergens,
        safetyStatus: safetyStatus,
        localImagePath: localImagePath,
      );

      // 7. Save to history
      await _saveScanToHistory(userId: userId, scanData: scanData, ingredientsText: ingredientsText);

      return ScanResult(
        success: true,
        message: safetyStatus == 'safe' ? 'المنتج آمن' : 'المنتج غير آمن',
        data: scanData,
      );
    } catch (e) {
      print("🔥 ScanService ERROR: $e");
      return ScanResult(success: false, message: "فشل تحليل الصورة");
    }
  }

  static Future<String?> _saveImageLocally(Uint8List imageBytes) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final scansDir = Directory('${dir.path}/scans');
      if (!await scansDir.exists()) await scansDir.create(recursive: true);
      final fileName = 'scan_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File('${scansDir.path}/$fileName');
      await file.writeAsBytes(imageBytes);
      print('✅ Image saved: ${file.path}');
      return file.path;
    } catch (e) {
      print('⚠️ Image save failed: $e');
      return null;
    }
  }

  static Future<ScanResult> getScanHistory({required String userId}) async {
    try {
      final data = await _supabase
          .from('scanhistory')
          .select()
          .eq('user_id', userId)
          .order('scan_date', ascending: false);
      return ScanResult(success: true, message: 'تم جلب السجل', data: data);
    } catch (e) {
      try {
        final localData = await LocalDB.getScanHistory(userId: userId);
        return ScanResult(success: true, message: 'تم جلب السجل محلياً', data: localData);
      } catch (_) {
        return ScanResult(success: false, message: 'فشل جلب السجل');
      }
    }
  }

  static Future<void> _saveScanToHistory({
    required String userId,
    required ProductScanData scanData,
    required String ingredientsText,
  }) async {
    try {
      final foundAllergensJson = jsonEncode(scanData.detectedAllergens);

      // Save to Supabase — only columns that exist
      await _supabase.from('scanhistory').insert({
        'user_id': userId,
        'product_name': scanData.productName,
        'found_allergens': foundAllergensJson,
        'safety_status': scanData.safetyStatus,
        'ingredients_text': ingredientsText,
        'scan_date': DateTime.now().toIso8601String(),
      });

      // Save to SQLite with local image path
      await LocalDB.saveScanHistory(
        userId: userId,
        productName: scanData.productName,
        ingredientsText: ingredientsText,
        foundAllergens: foundAllergensJson,
        safetyStatus: scanData.safetyStatus,
        localImagePath: scanData.localImagePath,
      );
    } catch (e) {
      print('⚠️ History save failed: $e');
    }
  }

  static const Map<String, List<String>> _allergyKeywords = {
    'milk': ['milk', 'dairy', 'lactose', 'whey', 'casein', 'حليب', 'لاكتوز', 'كازين'],
    'eggs': ['egg', 'eggs', 'albumin', 'بيض', 'ألبومين'],
    'gluten': ['wheat', 'gluten', 'barley', 'rye', 'flour', 'قمح', 'جلوتين', 'شعير', 'دقيق'],
    'fish': ['fish', 'salmon', 'tuna', 'سمك', 'سلمون', 'تونة'],
    'peanuts': ['peanut', 'فول سوداني'],
    'soybeans': ['soy', 'soya', 'صويا'],
    'treenuts': ['almond', 'cashew', 'walnut', 'pistachio', 'hazelnut', 'لوز', 'كاجو', 'جوز', 'فستق', 'بندق'],
    'sesame': ['sesame', 'tahini', 'سمسم', 'طحينة'],
    'crustaceans': ['shrimp', 'crab', 'lobster', 'روبيان', 'كركند'],
    'celery': ['celery', 'كرفس'],
    'mustard': ['mustard', 'خردل'],
    'sulfur': ['sulphite', 'sulfite', 'e220', 'e221', 'e222', 'كبريتيت'],
    'lupin': ['lupin', 'lupine', 'ترمس'],
    'mollusks': ['mollusc', 'mollusk', 'squid', 'oyster', 'رخويات', 'حبار'],
  };

  static const Map<String, String> _allergyArabicNames = {
    'milk': 'الحليب ومشتقاته',
    'eggs': 'البيض',
    'gluten': 'القمح / الجلوتين',
    'fish': 'الأسماك',
    'peanuts': 'الفول السوداني',
    'soybeans': 'فول الصويا',
    'treenuts': 'المكسرات',
    'sesame': 'السمسم',
    'crustaceans': 'القشريات',
    'celery': 'الكرفس',
    'mustard': 'الخردل',
    'sulfur': 'ثاني أكسيد الكبريت',
    'lupin': 'الترمس',
    'mollusks': 'الرخويات',
  };
}