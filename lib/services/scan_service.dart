// Scan.service.dart
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
  final List<String> detectedAllergenTypes;
  final List<String> llmSuggestedAlternatives;
  final String barcode;
  final String imageUrl;

  final List<String> ingredients;
  final List<String> detectedAllergens;

  final List<String> hiddenSources;        // 🔥 جديد
  final List<String> warningStatements;    // 🔥 جديد

  final String safetyStatus;
  final String? localImagePath;
  final String? remoteImageUrl; // ✅ Supabase Storage URL

  ProductScanData({
    required this.productName,
    required this.ingredients,
    required this.detectedAllergens,
    required this.detectedAllergenTypes,
    required this.llmSuggestedAlternatives,
    required this.hiddenSources,        // 🔥
    required this.warningStatements,    // 🔥
    required this.safetyStatus,
    this.localImagePath,
    this.remoteImageUrl,
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
      // 1. Save image locally + upload to Supabase Storage
      final localImagePath = await _saveImageLocally(imageBytes);
      final remoteImageUrl = await _uploadImageToStorage(imageBytes, userId);

      // 2. Analyze with Gemini
      final gemini = GeminiService();
      final aiResult = await gemini.analyzeProductImage(imageBytes);
      print("🧠 AI RESULT: $aiResult");

      // 3. Extract detected allergens
      final List<String> geminiIngredients = [];
      final List<String> detectedAllergenTypes = [];
      final rawAllergens = aiResult["detected_allergens"] ?? [];

      for (final allergenGroup in rawAllergens) {
        if (allergenGroup is Map) {
          final type = allergenGroup["allergen_type"]?.toString() ?? '';
          if (type.isNotEmpty && !detectedAllergenTypes.contains(type)) {
            detectedAllergenTypes.add(type);
          }
          // ✅ Extract ALL ingredients listed under this allergen group
          final ingredients = allergenGroup["ingredients"];
          if (ingredients is List) {
            for (final ingredient in ingredients) {
              if (ingredient is String && ingredient.trim().isNotEmpty) {
                if (!geminiIngredients.contains(ingredient.trim())) {
                  geminiIngredients.add(ingredient.trim());
                }
              }
            }
          }
        }
      }

      // ✅ Also extract all_ingredients if Gemini provides them
      final allIngredients = aiResult["all_ingredients"];
      if (allIngredients is List) {
        for (final ingredient in allIngredients) {
          if (ingredient is String && ingredient.trim().isNotEmpty) {
            if (!geminiIngredients.contains(ingredient.trim())) {
              geminiIngredients.add(ingredient.trim());
            }
          }
        }
      }

      // 4. Extract LLM suggested alternatives (Arabic)
      final List<String> llmSuggestedAlternatives = [];
      final rawSuggestions = aiResult["suggested_alternatives"] ?? [];
      for (final suggestion in rawSuggestions) {
        if (suggestion is Map) {
          final alternativesAr = suggestion["alternatives_ar"];
          final alternatives = alternativesAr ?? suggestion["alternatives"];
          if (alternatives is List) {
            for (final alt in alternatives) {
              if (alt is String && alt.trim().isNotEmpty) {
                if (!llmSuggestedAlternatives.contains(alt.trim())) {
                  llmSuggestedAlternatives.add(alt.trim());
                }
              }
            }
          }
        }
      }
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

      if (geminiIngredients.isEmpty && detectedAllergenTypes.isEmpty) {
        return ScanResult(success: false, message: "ما تم التعرف على المكونات");
      }

      // 5. Get user allergies
      final userAllergyIds = await LocalDB.getUserAllergies(userId: userId);
      final userAllergyStrings = userAllergyIds
          .map((id) => ProfileService.allergyReverseMap[id])
          .whereType<String>()
          .toSet();

      // 6. Cross-reference with user allergies
      final List<String> detectedAllergens = [];
      final List<String> userDetectedTypes = [];

      for (final type in detectedAllergenTypes) {
        if (userAllergyStrings.contains(type)) {
          final arabicName = _allergyArabicNames[type] ?? type;
          if (!detectedAllergens.contains(arabicName)) {
            detectedAllergens.add(arabicName);
            userDetectedTypes.add(type);
          }
        }
      }

      // Fallback keyword check
      if (detectedAllergens.isEmpty && geminiIngredients.isNotEmpty) {
        final lowerText = geminiIngredients.join(' ').toLowerCase();
        for (final allergyId in userAllergyStrings) {
          final keywords = _allergyKeywords[allergyId] ?? [];
          for (final keyword in keywords) {
            if (lowerText.contains(keyword)) {
              final arabicName = _allergyArabicNames[allergyId] ?? allergyId;
              if (!detectedAllergens.contains(arabicName)) {
                detectedAllergens.add(arabicName);
                userDetectedTypes.add(allergyId);
              }
              break;
            }
          }
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

      final safetyStatus = detectedAllergens.isEmpty ? 'safe' : 'unsafe';
      final ingredientsText = geminiIngredients.join(', ');
      final safetyStatus =
          userMatchedAllergens.isEmpty ? 'safe' : 'unsafe';

      final scanData = ProductScanData(
        productName: productName,
        ingredients: geminiIngredients,
        detectedAllergens: detectedAllergens,
        detectedAllergenTypes: userDetectedTypes,
        llmSuggestedAlternatives: llmSuggestedAlternatives,
        safetyStatus: safetyStatus,
        localImagePath: localImagePath,
        remoteImageUrl: remoteImageUrl,
      );

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
        ingredientsText: ingredientsText,
      );

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

  // ✅ Save image locally for offline use
  static Future<String?> _saveImageLocally(Uint8List imageBytes) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final scansDir = Directory('${dir.path}/scans');
      if (!await scansDir.exists()) await scansDir.create(recursive: true);
      final fileName = 'scan_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File('${scansDir.path}/$fileName');
      await file.writeAsBytes(imageBytes);
      print('✅ Image saved locally: ${file.path}');
      return file.path;
    } catch (e) {
      print('⚠️ Local image save failed: $e');
      return null;
    }
  }

  // ✅ Upload image to Supabase Storage for cross-device access
  static Future<String?> _uploadImageToStorage(Uint8List imageBytes, String userId) async {
    try {
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'scans/$fileName';

      await _supabase.storage
          .from('scans')
          .uploadBinary(path, imageBytes, fileOptions: const FileOptions(contentType: 'image/jpeg'));

      final url = _supabase.storage.from('scans').getPublicUrl(path);
      print('✅ Image uploaded to Supabase: $url');
      return url;
    } catch (e) {
      print('⚠️ Supabase image upload failed: $e');
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

      // ✅ Save remote URL to Supabase so image shows on any device
      await _supabase.from('scanhistory').insert({
        'user_id': userId,
        'product_name': scanData.productName,
        'found_allergens': foundAllergensJson,
        'safety_status': scanData.safetyStatus,
        'ingredients_text': ingredientsText,
        'scan_date': DateTime.now().toIso8601String(),
        'local_image_path': scanData.remoteImageUrl ?? '', // store remote URL here
      });

      // ✅ Save local path to SQLite for offline display
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
    'eggs': ['egg', 'eggs', 'albumin', 'بيض'],
    'gluten': ['wheat', 'gluten', 'barley', 'rye', 'flour', 'قمح', 'جلوتين', 'شعير', 'دقيق'],
    'fish': ['fish', 'salmon', 'tuna', 'سمك'],
    'peanuts': ['peanut', 'فول سوداني'],
    'soybeans': ['soy', 'soya', 'صويا'],
    'treenuts': ['almond', 'cashew', 'walnut', 'pistachio', 'hazelnut', 'مكسرات', 'لوز'],
    'sesame': ['sesame', 'tahini', 'سمسم', 'طحينة'],
    'crustaceans': ['shrimp', 'crab', 'lobster', 'روبيان'],
    'celery': ['celery', 'كرفس'],
    'mustard': ['mustard', 'خردل'],
    'sulfur': ['sulphite', 'sulfite', 'e220', 'كبريتيت'],
    'lupin': ['lupin', 'lupine', 'ترمس'],
    'mollusks': ['mollusc', 'squid', 'oyster', 'رخويات'],
  };
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