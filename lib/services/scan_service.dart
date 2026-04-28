import 'dart:async' show unawaited;
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
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
  final List<String> traceWarnings;
  final List<String> detectedAllergens;
  final List<String> detectedAllergenTypes;
  final List<String> llmSuggestedAlternatives;
  final List<Map<String, dynamic>> llmRawAlternatives;
  final String productTypeAr;
  final String safetyStatus;
  final String? localImagePath;
  final String? remoteImageUrl;
  final List<AlternativeProduct> mergedAlternatives;

  ProductScanData({
    required this.productName,
    required this.ingredients,
    this.traceWarnings = const [],
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

  // ── Timing fields (populated on each scan) ────────────────────────────
  static int lastCompressMs = 0;
  static int lastGeminiMs   = 0;
  static int lastAltMs      = 0;

  // ── Optimization 3: In-memory allergy cache ──────────────────────────
  static final Map<String, List<String>> _allergyCache = {};

  static void clearAllergyCache(String userId) {
    _allergyCache.remove(userId);
  }

  // ── Optimization 8: History prefetch cache ───────────────────────────
  static String? _historyCacheUserId;
  static List<Map<String, dynamic>>? _historyCache;

  static void _invalidateHistoryCache() {
    _historyCacheUserId = null;
    _historyCache = null;
  }

  static Future<void> prefetchHistory({required String userId}) async {
    try {
      final result = await getScanHistory(userId: userId);
      if (result.success && result.data != null) {
        final raw = result.data as List;
        _historyCache =
            raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _historyCacheUserId = userId;
      }
    } catch (e) {
      print('⚠️ prefetchHistory failed: $e');
    }
  }

  static Future<ScanResult> getScanHistoryCached(
      {required String userId}) async {
    if (_historyCacheUserId == userId && _historyCache != null) {
      final cached = List<Map<String, dynamic>>.from(_historyCache!);
      _historyCacheUserId = null;
      _historyCache = null;
      return ScanResult(success: true, message: 'تم جلب السجل', data: cached);
    }
    return getScanHistory(userId: userId);
  }

  // ── Optimization 2: Image compression ────────────────────────────────
  static Future<Uint8List> _compressForGemini(Uint8List imageBytes) async {
    if (imageBytes.length < 400 * 1024) return imageBytes;
    try {
      final dir = await getTemporaryDirectory();
      final ts = DateTime.now().millisecondsSinceEpoch;
      final inputFile = File('${dir.path}/input_$ts.jpg');
      final outputPath = '${dir.path}/output_$ts.jpg';

      await inputFile.writeAsBytes(imageBytes);

      final XFile? result = await FlutterImageCompress.compressAndGetFile(
        inputFile.path,
        outputPath,
        minWidth: 800,
        minHeight: 0,
        quality: 82,
        format: CompressFormat.jpeg,
      );

      try { await inputFile.delete(); } catch (_) {}

      if (result == null) return imageBytes;

      final compressedBytes = await result.readAsBytes();

      try { await File(outputPath).delete(); } catch (_) {}

      if (compressedBytes.length >= imageBytes.length) return imageBytes;

      return compressedBytes;
    } catch (e) {
      print('⚠️ Image compression failed, using original: $e');
      return imageBytes;
    }
  }

  static Future<ScanResult> scanFromImage({
    required Uint8List imageBytes,
    required String userId,
    String productName = 'منتج من صورة',

  })
  
   async {
    lastCompressMs = 0;
  lastGeminiMs   = 0;
  lastAltMs      = 0;
  try {
      // ── Optimization 1: Start upload + local save immediately in background
      final remoteUrlFuture = _uploadImageToStorage(imageBytes, userId);
      final localPathFuture = _saveImageLocally(imageBytes);

      // ── Optimization 3: Serve allergy data from cache ─────────────────
      Set<String> userAllergyStrings;
      if (_allergyCache.containsKey(userId)) {
        userAllergyStrings = Set<String>.from(_allergyCache[userId]!);
      } else {
        final userAllergyIds = await LocalDB.getUserAllergies(userId: userId);
        userAllergyStrings = userAllergyIds
            .map((id) => ProfileService.allergyReverseMap[id])
            .whereType<String>()
            .toSet();
        _allergyCache[userId] = userAllergyStrings.toList();
      }

      final userAllergiesAr = userAllergyStrings
          .map((s) => _allergyArabicNames[s] ?? s)
          .join('، ');

      // ── Optimization 2: Compress only bytes that go to Gemini ─────────
      final compSw = Stopwatch()..start();
      final geminiBytes = await _compressForGemini(imageBytes);
      lastCompressMs = compSw.elapsedMilliseconds;
      print('🗜 [2/4] compression: ${lastCompressMs}ms');

      final gemini = GeminiService();

      final aiSw = Stopwatch()..start();
      final aiResult = await gemini.analyzeProductImage(
        geminiBytes,
        productName: productName,
        userAllergies: userAllergiesAr,
      );
      lastGeminiMs = aiSw.elapsedMilliseconds;
      print('🤖 [3/4] geminiAPI: ${lastGeminiMs}ms');
      print("🧠 AI RESULT: $aiResult");

      // ── Extract actual ingredients from detected_allergens ─────────────────
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

      // ── Extract trace warnings: hidden_sources + warning_statements ────
      final List<String> traceWarnings = [];

      final rawHiddenSources = aiResult["hidden_sources"] ?? [];
      for (final source in rawHiddenSources) {
        if (source is String && source.trim().isNotEmpty) {
          if (!traceWarnings.contains(source.trim())) {
            traceWarnings.add(source.trim());
          }
        }
      }

      final rawWarningStatements = aiResult["warning_statements"] ?? [];
      for (final warning in rawWarningStatements) {
        if (warning is String && warning.trim().isNotEmpty) {
          if (!traceWarnings.contains(warning.trim())) {
            traceWarnings.add(warning.trim());
          }
        }
      }

      print("⚠️ Trace warnings extracted: ${traceWarnings.length}");

      // ── Extract LLM suggestions ────────────────────────────────────────
      final List<String> llmSuggestedAlternatives = [];
      final List<Map<String, dynamic>> llmRawAlternatives = [];
      final String productTypeAr = aiResult["product_type_ar"]?.toString() ?? '';
      final String productCategory = aiResult["product_category"]?.toString() ?? '';
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

      final bool aiProcessedImage = aiResult.containsKey('is_safe_for_user');
      if (!aiProcessedImage) {
        return ScanResult(success: false, message: "لم يتم التعرف على المكونات");
      }

      final String productType = aiResult["product_type_ar"]?.toString() ?? '';
      final String confidence = aiResult["confidence"]?.toString() ?? 'low';
      final bool hasAnyContent = geminiIngredients.isNotEmpty ||
          detectedAllergenTypes.isNotEmpty ||
          traceWarnings.isNotEmpty ||
          productType.isNotEmpty;

      if (!hasAnyContent) {
        return ScanResult(
          success: false,
          message: "الصورة غير واضحة، يرجى التصوير في إضاءة جيدة وأن تكون قائمة المكونات ظاهرة بوضوح",
        );
      }

      // ── Allergen detection from actual ingredients ─────────────────────
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

      // Fallback: keyword scan on actual ingredients text
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

      // ── Allergen detection from trace warnings ─────────────────────────
      if (traceWarnings.isNotEmpty) {
        final lowerTraceText = traceWarnings.join(' ').toLowerCase();
        for (final allergyId in userAllergyStrings) {
          if (!userDetectedTypes.contains(allergyId)) {
            final keywords = _allergyKeywords[allergyId] ?? [];
            for (final keyword in keywords) {
              if (lowerTraceText.contains(keyword)) {
                final arabicName = _allergyArabicNames[allergyId] ?? allergyId;
                if (!detectedAllergens.contains(arabicName)) {
                  detectedAllergens.add(arabicName);
                  userDetectedTypes.add(allergyId);
                  print('⚠️ Trace warning triggered allergen: $allergyId');
                }
                break;
              }
            }
          }
        }
      }

      final safetyStatus = detectedAllergens.isEmpty ? 'safe' : 'unsafe';

      final ingredientsText = [...geminiIngredients, ...traceWarnings].join('|||');

      List<AlternativeProduct> mergedAlternatives = [];
      if (safetyStatus == 'unsafe') {
        try {
          final altSw = Stopwatch()..start();
          mergedAlternatives = await AlternativesService.getAlternatives(
            allUserAllergyTypes: userAllergyStrings.toList(),
            detectedAllergenTypes: userDetectedTypes,
            llmSuggestedAlternatives: llmSuggestedAlternatives,
            llmRawAlternatives: llmRawAlternatives,
            productTypeAr: productTypeAr,
            productCategory: productCategory,
          );
          lastAltMs = altSw.elapsedMilliseconds;
          print('🔍 [4/4] alternatives: ${lastAltMs}ms');
        } catch (e) {
          lastAltMs = 0;
          print('⚠️ Alternatives query failed: $e');
        }
      } else {
        lastAltMs = 0;
      }

      // ── Optimization 1: Collect background futures now (after Gemini) ──
      final localImagePath = await localPathFuture;
      final remoteImageUrl = await remoteUrlFuture;

      final scanData = ProductScanData(
        productName: productName,
        ingredients: geminiIngredients,
        traceWarnings: traceWarnings,
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

      // ── Optimization 4: Fire-and-forget history save ──────────────────
      unawaited(_saveScanToHistory(
        userId: userId,
        scanData: scanData,
        ingredientsText: ingredientsText,
      ));

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

  // ── Everything below is UNTOUCHED ─────────────────────────────────────

  static Future<String?> _saveImageLocally(Uint8List imageBytes) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final scansDir = Directory('${dir.path}/scans');
      if (!await scansDir.exists()) await scansDir.create(recursive: true);
      final fileName = 'scan_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File('${scansDir.path}/$fileName');
      await file.writeAsBytes(imageBytes);
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
      return url;
    } catch (e) {
      print('⚠️ Upload failed: $e');
      return null;
    }
  }

  // ── Optimization 6: History query with .limit(50) ─────────────────────
  static Future<ScanResult> getScanHistory({required String userId}) async {
    final localData = await LocalDB.getScanHistory(userId: userId);

    final Map<String, Map<String, String>> localMap = {};
    for (final row in localData) {
      final supabaseId = row['supabase_id']?.toString() ?? '';
      if (supabaseId.isNotEmpty) {
        localMap[supabaseId] = {
          'local_image_path': row['local_image_path']?.toString() ?? '',
          'alternatives_json': row['alternatives_json']?.toString() ?? '',
        };
      }
    }

    try {
      final data = await _supabase
          .from('scanhistory')
          .select()
          .eq('user_id', userId)
          .order('scan_date', ascending: false)
          .limit(50);

      final merged = (data as List).map((row) {
        final map = Map<String, dynamic>.from(row as Map);
        final supId = map['history_id']?.toString() ?? '';
        if (supId.isNotEmpty && localMap.containsKey(supId)) {
          final local = localMap[supId]!;
          if (local['local_image_path']!.isNotEmpty) {
            map['local_image_path'] = local['local_image_path'];
          }
          if ((map['alternatives_json'] == null || map['alternatives_json'] == '[]') &&
              local['alternatives_json']!.isNotEmpty) {
            map['alternatives_json'] = local['alternatives_json'];
          }
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
    await LocalDB.deleteScanHistory(userId: userId);
    try {
      await _supabase.from('scanhistory').delete().eq('user_id', userId);
    } catch (e) {
      print('⚠️ Supabase delete all failed (offline?): $e');
    }
  }

  static Future<void> deleteSingleScan({
    required String userId,
    required int historyId,
    String? scanDate,
  }) async {
    await LocalDB.deleteSingleScan(
      supabaseHistoryId: historyId,
      scanDate: scanDate,
    );
    try {
      await _supabase.from('scanhistory').delete().eq('history_id', historyId);
    } catch (e) {
      print('⚠️ Supabase delete single failed (offline?): $e');
    }
  }

  static Future<void> _saveScanToHistory({
    required String userId,
    required ProductScanData scanData,
    required String ingredientsText,
  }) async {
    // ── Optimization 8: Bust stale prefetch cache on every new scan ──────
    _invalidateHistoryCache();

    final scanDate = DateTime.now().toIso8601String();

    try {
      final foundAllergensJson = jsonEncode(scanData.detectedAllergens);
      final alternativesJson = AlternativesService.toJsonList(scanData.mergedAlternatives);

      final response = await _supabase.from('scanhistory').insert({
        'user_id': userId,
        'product_name': scanData.productName,
        'found_allergens': foundAllergensJson,
        'safety_status': scanData.safetyStatus,
        'ingredients_text': ingredientsText,
        'scan_date': scanDate,
        'local_image_path': scanData.localImagePath ?? '',
        'remote_image_url': scanData.remoteImageUrl ?? '',
        'alternatives_json': alternativesJson,
      }).select('history_id').single();

      final supabaseId = response['history_id']?.toString() ?? '';

      await LocalDB.saveScanHistory(
        userId: userId,
        productName: scanData.productName,
        ingredientsText: ingredientsText,
        foundAllergens: foundAllergensJson,
        safetyStatus: scanData.safetyStatus,
        localImagePath: scanData.localImagePath,
        remoteImageUrl: scanData.remoteImageUrl,
        alternativesJson: alternativesJson,
        supabaseId: supabaseId,
        scanDate: scanDate,
      );
    } catch (e) {
      print('⚠️ History save failed: $e');
      try {
        final foundAllergensJson = jsonEncode(scanData.detectedAllergens);
        final alternativesJson = AlternativesService.toJsonList(scanData.mergedAlternatives);
        await LocalDB.saveScanHistory(
          userId: userId,
          productName: scanData.productName,
          ingredientsText: ingredientsText,
          foundAllergens: foundAllergensJson,
          safetyStatus: scanData.safetyStatus,
          localImagePath: scanData.localImagePath,
          remoteImageUrl: scanData.remoteImageUrl,
          alternativesJson: alternativesJson,
          scanDate: scanDate,
        );
      } catch (e2) {
        print('⚠️ Local save also failed: $e2');
      }
    }
  }

  static const Map<String, List<String>> _allergyKeywords = {
    'milk'        : ['milk', 'dairy', 'lactose', 'whey', 'casein', 'حليب', 'لاكتوز', 'كازين'],
    'eggs'        : ['egg', 'eggs', 'albumin', 'بيض'],
    'gluten'      : ['wheat', 'gluten', 'barley', 'rye', 'flour', 'قمح', 'جلوتين', 'شعير', 'دقيق'],
    'fish'        : ['fish', 'salmon', 'tuna', 'سمك'],
    'peanuts'     : ['peanut', 'فول سوداني'],
    'soybeans'    : ['soy', 'soya', 'صويا'],
    'treenuts'    : ['almond', 'cashew', 'walnut', 'pistachio', 'hazelnut',
                     'nuts', 'tree nut', 'مكسرات', 'لوز'],
    'sesame'      : ['sesame', 'tahini', 'سمسم', 'طحينة'],
    'crustaceans' : ['shrimp', 'crab', 'lobster', 'روبيان'],
    'celery'      : ['celery', 'كرفس'],
    'mustard'     : ['mustard', 'خردل'],
    'sulfur'      : ['sulphite', 'sulfite', 'e220', 'كبريتيت'],
    'lupin'       : ['lupin', 'lupine', 'ترمس'],
    'mollusks'    : ['mollusc', 'squid', 'oyster', 'رخويات'],
  };

  static const Map<String, String> _allergyArabicNames = {
    'milk'        : 'الحليب ومشتقاته',
    'eggs'        : 'البيض',
    'gluten'      : 'القمح / الجلوتين',
    'fish'        : 'الأسماك',
    'peanuts'     : 'الفول السوداني',
    'soybeans'    : 'فول الصويا',
    'treenuts'    : 'المكسرات',
    'sesame'      : 'السمسم',
    'crustaceans' : 'القشريات',
    'celery'      : 'الكرفس',
    'mustard'     : 'الخردل',
    'sulfur'      : 'ثاني أكسيد الكبريت',
    'lupin'       : 'الترمس',
    'mollusks'    : 'الرخويات',
  };
}