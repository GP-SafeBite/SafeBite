import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/local_db.dart';
import 'profile_service.dart';
import 'gemini_service.dart';
import 'alternatives_service.dart';

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
  final List<Map<String, dynamic>> llmRawAlternatives;
  final String productTypeAr;
  final String safetyStatus;
  final String? localImagePath;
  final String? remoteImageUrl;
  // ✅ Issue 3: full merged alternatives saved at scan time
  final List<AlternativeProduct> mergedAlternatives;

  ProductScanData({
    required this.productName,
    required this.ingredients,
    required this.detectedAllergens,
    required this.detectedAllergenTypes,
    required this.llmSuggestedAlternatives,
    required this.llmRawAlternatives,
    required this.productTypeAr,
    required this.safetyStatus,
    this.localImagePath,
    this.remoteImageUrl,
    this.mergedAlternatives = const [],
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
      // 1. Save image locally + upload to Supabase Storage in parallel
      final localPathFuture = _saveImageLocally(imageBytes);
      final remoteUrlFuture = _uploadImageToStorage(imageBytes, userId);
      final results = await Future.wait([localPathFuture, remoteUrlFuture]);
      final localImagePath = results[0];
      final remoteImageUrl = results[1];

      // 2. Get user allergies BEFORE calling Gemini
      final userAllergyIds = await LocalDB.getUserAllergies(userId: userId);
      final userAllergyStrings = userAllergyIds
          .map((id) => ProfileService.allergyReverseMap[id])
          .whereType<String>()
          .toSet();
      final userAllergiesAr = userAllergyStrings
          .map((s) => _allergyArabicNames[s] ?? s)
          .join('، ');

      // 3. Analyze with Gemini
      final gemini = GeminiService();
      final aiResult = await gemini.analyzeProductImage(
        imageBytes,
        productName: productName,
        userAllergies: userAllergiesAr,
      );
      print("🧠 AI RESULT: $aiResult");

      // 4. Extract detected allergens
      final List<String> geminiIngredients = [];
      final List<String> detectedAllergenTypes = [];
      final rawAllergens = aiResult["detected_allergens"] ?? [];

      for (final allergenGroup in rawAllergens) {
        if (allergenGroup is Map) {
          final type = allergenGroup["allergen_type"]?.toString() ?? '';
          if (type.isNotEmpty && !detectedAllergenTypes.contains(type)) {
            detectedAllergenTypes.add(type);
          }
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

      // 5. Extract LLM suggested alternatives
      final List<String> llmSuggestedAlternatives = [];
      final List<Map<String, dynamic>> llmRawAlternatives = [];
      final String productTypeAr = aiResult["product_type_ar"]?.toString() ?? '';
      final rawSuggestions = aiResult["suggested_alternatives"] ?? [];
      for (final suggestion in rawSuggestions) {
        if (suggestion is Map) {
          final name = suggestion["name"]?.toString() ?? '';
          if (name.isNotEmpty && !llmSuggestedAlternatives.contains(name)) {
            llmSuggestedAlternatives.add(name);
            llmRawAlternatives.add(Map<String, dynamic>.from(suggestion));
          }
        }
      }

      if (geminiIngredients.isEmpty && detectedAllergenTypes.isEmpty) {
        return ScanResult(success: false, message: "ما تم التعرف على المكونات");
      }

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
        }
      }

      final safetyStatus = detectedAllergens.isEmpty ? 'safe' : 'unsafe';
      final ingredientsText = geminiIngredients.join(', ');

      // ✅ Issue 3: Query DB alternatives NOW and merge with LLM
      // Save the full merged list so history can display it without re-querying
      List<AlternativeProduct> mergedAlternatives = [];
      if (safetyStatus == 'unsafe' && userDetectedTypes.isNotEmpty) {
        try {
          mergedAlternatives = await AlternativesService.getAlternatives(
            detectedAllergenTypes: userDetectedTypes,
            llmSuggestedAlternatives: llmSuggestedAlternatives,
            llmRawAlternatives: llmRawAlternatives,
            productTypeAr: productTypeAr,
          );
        } catch (e) {
          print('⚠️ Alternatives query at scan time failed: $e');
        }
      }

      final scanData = ProductScanData(
        productName: productName,
        ingredients: geminiIngredients,
        detectedAllergens: detectedAllergens,
        detectedAllergenTypes: userDetectedTypes,
        llmSuggestedAlternatives: llmSuggestedAlternatives,
        llmRawAlternatives: llmRawAlternatives,
        productTypeAr: productTypeAr,
        safetyStatus: safetyStatus,
        localImagePath: localImagePath,
        remoteImageUrl: remoteImageUrl,
        mergedAlternatives: mergedAlternatives,
      );

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
      print('⚠️ Local save failed: $e');
      return null;
    }
  }

  static Future<String?> _uploadImageToStorage(Uint8List imageBytes, String userId) async {
    try {
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'scans/$fileName';
      await _supabase.storage
          .from('scans')
          .uploadBinary(path, imageBytes, fileOptions: const FileOptions(contentType: 'image/jpeg'));
      final url = _supabase.storage.from('scans').getPublicUrl(path);
      print('✅ Image uploaded: $url');
      return url;
    } catch (e) {
      print('⚠️ Upload failed: $e');
      return null;
    }
  }

  static Future<ScanResult> getScanHistory({required String userId}) async {
    final localData = await LocalDB.getScanHistory(userId: userId);
    final Map<String, String> localImageMap = {};
    final Map<String, String> localAltMap = {};
    for (final row in localData) {
      final date = row['scan_date']?.toString() ?? '';
      final localPath = row['local_image_path']?.toString() ?? '';
      final altJson = row['alternatives_json']?.toString() ?? '';
      if (date.isNotEmpty) {
        if (localPath.isNotEmpty) localImageMap[date] = localPath;
        if (altJson.isNotEmpty && altJson != '[]') localAltMap[date] = altJson;
      }
    }

    try {
      final data = await _supabase
          .from('scanhistory')
          .select()
          .eq('user_id', userId)
          .order('scan_date', ascending: false);

      final merged = (data as List).map((row) {
        final map = Map<String, dynamic>.from(row as Map);
        final date = map['scan_date']?.toString() ?? '';
        if (localImageMap.containsKey(date)) {
          map['local_image_path'] = localImageMap[date];
        }
        // ✅ Merge alternatives_json from SQLite if Supabase doesn't have it
        if ((map['alternatives_json'] == null || map['alternatives_json'] == '[]') &&
            localAltMap.containsKey(date)) {
          map['alternatives_json'] = localAltMap[date];
        }
        return map;
      }).toList();

      return ScanResult(success: true, message: 'تم جلب السجل', data: merged);
    } catch (e) {
      print('⚠️ Supabase offline, using SQLite: $e');
      return ScanResult(success: true, message: 'تم جلب السجل محلياً', data: localData);
    }
  }

  static Future<void> deleteAllHistory({required String userId}) async {
    try {
      await _supabase.from('scanhistory').delete().eq('user_id', userId);
      await LocalDB.deleteScanHistory(userId: userId);
    } catch (e) {
      print('⚠️ Delete all failed: $e');
    }
  }

  static Future<void> deleteSingleScan({
    required String userId,
    required int historyId,
  }) async {
    try {
      await _supabase.from('scanhistory').delete().eq('history_id', historyId);
      await LocalDB.deleteSingleScan(historyId: historyId);
    } catch (e) {
      print('⚠️ Delete single failed: $e');
    }
  }

  static Future<void> _saveScanToHistory({
    required String userId,
    required ProductScanData scanData,
    required String ingredientsText,
  }) async {
    try {
      final foundAllergensJson = jsonEncode(scanData.detectedAllergens);
      // ✅ Issue 3: save full merged alternatives (DB + LLM) not just LLM strings
      final alternativesJson = AlternativesService.toJsonList(scanData.mergedAlternatives);

      await _supabase.from('scanhistory').insert({
        'user_id': userId,
        'product_name': scanData.productName,
        'found_allergens': foundAllergensJson,
        'safety_status': scanData.safetyStatus,
        'ingredients_text': ingredientsText,
        'scan_date': DateTime.now().toIso8601String(),
        'local_image_path': scanData.localImagePath ?? '',
        'remote_image_url': scanData.remoteImageUrl ?? '',
        'alternatives_json': alternativesJson,
      });

      await LocalDB.saveScanHistory(
        userId: userId,
        productName: scanData.productName,
        ingredientsText: ingredientsText,
        foundAllergens: foundAllergensJson,
        safetyStatus: scanData.safetyStatus,
        localImagePath: scanData.localImagePath,
        remoteImageUrl: scanData.remoteImageUrl,
        alternativesJson: alternativesJson,
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