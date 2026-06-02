// Scan Service - Orchestrate product image scanning, allergen detection, and history management

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

  // Return a copy of this instance with an updated remoteImageUrl
  ProductScanData copyWith({String? remoteImageUrl}) {
    return ProductScanData(
      productName: productName,
      ingredients: ingredients,
      traceWarnings: traceWarnings,
      detectedAllergens: detectedAllergens,
      detectedAllergenTypes: detectedAllergenTypes,
      llmSuggestedAlternatives: llmSuggestedAlternatives,
      llmRawAlternatives: llmRawAlternatives,
      productTypeAr: productTypeAr,
      safetyStatus: safetyStatus,
      localImagePath: localImagePath,
      remoteImageUrl: remoteImageUrl ?? this.remoteImageUrl,
      mergedAlternatives: mergedAlternatives,
    );
  }
}

class ScanService {
  static final _supabase = Supabase.instance.client;

  // Timing fields populated on each scan for performance reporting
  static int lastCompressMs = 0;
  static int lastGeminiMs   = 0;
  static int lastAltMs      = 0;

  // ── Caching ──────────────────────────────────────────────────────────────

  // In-memory cache mapping user ID to resolved allergy type strings
  static final Map<String, List<String>> _allergyCache = {};

  // Invalidate the allergy cache for a specific user after allergen profile changes
  static void clearAllergyCache(String userId) {
    _allergyCache.remove(userId);
  }

  static String? _historyCacheUserId;
  static List<Map<String, dynamic>>? _historyCache;

  // Invalidate the history prefetch cache after a new scan is saved
  static void _invalidateHistoryCache() {
    _historyCacheUserId = null;
    _historyCache = null;
  }

  // Prefetch and store scan history in memory while the user is on the home screen
  // so that HistoryScreen can render instantly from cache without a network request
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

  // Return scan history from the in-memory prefetch cache if available,
  // consuming and clearing the cache on use, then falling back to a live fetch
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

  // ── Image Processing ──────────────────────────────────────────────────────

  // Compress image bytes to reduce Gemini API payload size,
  // skipping compression when the image is already below the size threshold
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

  // ── Scan Pipeline ─────────────────────────────────────────────────────────

  // Execute the full scan pipeline: compress image, call Gemini for allergen analysis,
  // query safe alternatives, and persist the result asynchronously
  static Future<ScanResult> scanFromImage({
    required Uint8List imageBytes,
    required String userId,
    String productName = 'منتج من صورة',
  }) async {
    lastCompressMs = 0;
    lastGeminiMs   = 0;
    lastAltMs      = 0;
    try {
      // Begin image upload and local save in parallel without blocking the scan
      final remoteUrlFuture = _uploadImageToStorage(imageBytes, userId);
      final localPathFuture = _saveImageLocally(imageBytes);

      // Serve allergy profile from in-memory cache to avoid repeated database reads
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

      // Extract detected allergen types and ingredient strings from Gemini response
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

      // Extract trace warnings from hidden_sources and warning_statements,
      // excluding items already captured as direct ingredients
      final List<String> traceWarnings = [];
      final rawHiddenSources = aiResult["hidden_sources"] ?? [];
      for (final source in rawHiddenSources) {
        if (source is Map) {
          final ingredient = source["ingredient"]?.toString() ?? '';
          if (ingredient.isNotEmpty
              && !traceWarnings.contains(ingredient)
              && !geminiIngredients.contains(ingredient)) {
            traceWarnings.add(ingredient);
          }
        } else if (source is String && source.trim().isNotEmpty) {
          if (!traceWarnings.contains(source.trim())
              && !geminiIngredients.contains(source.trim())) {
            traceWarnings.add(source.trim());
          }
        }
      }

      final rawWarningStatements = aiResult["warning_statements"] ?? [];
      for (final warning in rawWarningStatements) {
        if (warning is String && warning.trim().isNotEmpty) {
          if (!traceWarnings.contains(warning.trim())
              && !geminiIngredients.contains(warning.trim())) {
            traceWarnings.add(warning.trim());
          }
        }
      }

      print("⚠️ Trace warnings extracted: ${traceWarnings.length}");

      final List<String> detectedAllergens = [];
      final List<String> userDetectedTypes = [];

      // Add allergens identified through hidden sources before processing direct ingredient matches
      final rawHiddenSources2 = aiResult["hidden_sources"] ?? [];
      for (final source in rawHiddenSources2) {
        if (source is Map) {
          final allergenType = source["allergen_type"]?.toString() ?? '';
          if (allergenType.isNotEmpty && userAllergyStrings.contains(allergenType)) {
            final arabicName = _allergyArabicNames[allergenType] ?? allergenType;
            if (!detectedAllergens.contains(arabicName)) {
              detectedAllergens.add(arabicName);
              if (!userDetectedTypes.contains(allergenType)) {
                userDetectedTypes.add(allergenType);
              }
            }
          }
        }
      }

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

      // Reject low-confidence results to avoid false negatives on unclear images
      if (confidence == 'low') {
        return ScanResult(
          success: false,
          message: "الصورة غير واضحة، يرجى التصوير في إضاءة جيدة وأن تكون قائمة المكونات ظاهرة بوضوح",
        );
      }

      if (!hasAnyContent) {
        return ScanResult(
          success: false,
          message: "الصورة غير واضحة، يرجى التصوير في إضاءة جيدة وأن تكون قائمة المكونات ظاهرة بوضوح",
        );
      }

      // Match detected allergen types against the user's allergy profile
      for (final type in detectedAllergenTypes) {
        if (userAllergyStrings.contains(type)) {
          final arabicName = _allergyArabicNames[type] ?? type;
          if (!detectedAllergens.contains(arabicName)) {
            detectedAllergens.add(arabicName);
            if (!userDetectedTypes.contains(type)) {
              userDetectedTypes.add(type);
            }
          }
        }
      }

      // Keyword-based fallback scan when Gemini returned no allergen matches
      if (detectedAllergens.isEmpty && geminiIngredients.isNotEmpty) {
        final lowerText = geminiIngredients.join(' ').toLowerCase();
        for (final allergyId in userAllergyStrings) {
          final keywords = _allergyKeywords[allergyId] ?? [];
          for (final keyword in keywords) {
            if (lowerText.contains(keyword)) {
              final arabicName = _allergyArabicNames[allergyId] ?? allergyId;
              if (!detectedAllergens.contains(arabicName)) {
                detectedAllergens.add(arabicName);
                if (!userDetectedTypes.contains(allergyId)) {
                  userDetectedTypes.add(allergyId);
                }
              }
              break;
            }
          }
        }
      }

      // Scan trace warning text for allergen keywords to capture cross-contamination risks
      if (traceWarnings.isNotEmpty) {
        final lowerTraceText = traceWarnings.join(' ').toLowerCase();
        for (final allergyId in userAllergyStrings) {
          if (!userDetectedTypes.contains(allergyId)) {
            final keywords = _allergyKeywords[allergyId] ?? [];
            for (final keyword in keywords) {
              if (lowerTraceText.contains(keyword) && !lowerTraceText.contains('no $keyword')) {
                final arabicName = _allergyArabicNames[allergyId] ?? allergyId;
                if (!detectedAllergens.contains(arabicName)) {
                  detectedAllergens.add(arabicName);
                  if (!userDetectedTypes.contains(allergyId)) {
                    userDetectedTypes.add(allergyId);
                  }
                  print('⚠️ Trace warning triggered allergen: $allergyId');
                }
                break;
              }
            }
          }
        }
      }

      final bool geminiSaysUnsafe = aiResult['is_safe_for_user'] == false;
      final safetyStatus = (detectedAllergens.isEmpty && !geminiSaysUnsafe) ? 'safe' : 'unsafe';

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

      // Resolve local image path immediately on-device without waiting for remote upload
      final localImagePath = await localPathFuture;

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
        remoteImageUrl: null,
        mergedAlternatives: mergedAlternatives,
      );

      // Fire-and-forget: upload image and save history without blocking the result screen
      unawaited(() async {
        try {
          final remoteImageUrl = await remoteUrlFuture;
          await _saveScanToHistory(
            userId: userId,
            scanData: scanData.copyWith(remoteImageUrl: remoteImageUrl),
            ingredientsText: ingredientsText,
          );
        } catch (e) {
          print('⚠️ Background save failed: $e');
        }
      }());

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

  // ── Storage Operations ───────────────────────────────────────────────────

  // Write image bytes to the device's local documents directory under a scans subdirectory
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

  // Upload image bytes to Supabase Storage and return the public URL
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

  // ── History Operations ───────────────────────────────────────────────────

  // Fetch scan history by merging Supabase records with local image paths and alternatives data.
  // Falls back to SQLite-only results when Supabase is unavailable.
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
          .limit(500);

      final merged = (data as List).map((row) {
        final map = Map<String, dynamic>.from(row as Map);
        final supId = map['history_id']?.toString() ?? '';
        if (supId.isNotEmpty && localMap.containsKey(supId)) {
          final local = localMap[supId]!;
          if (local['local_image_path']!.isNotEmpty) {
            map['local_image_path'] = local['local_image_path'];
          }
          // Prefer local alternatives data when Supabase record is missing or empty
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

  // Delete all scan history records for a user from both SQLite and Supabase
  static Future<void> deleteAllHistory({required String userId}) async {
    await LocalDB.deleteScanHistory(userId: userId);
    try {
      await _supabase.from('scanhistory').delete().eq('user_id', userId);
    } catch (e) {
      print('⚠️ Supabase delete all failed (offline?): $e');
    }
  }

  // Delete a single scan record by history ID from both SQLite and Supabase
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

  // Persist a completed scan to Supabase and SQLite with a shared timestamp.
  // Invalidates the history prefetch cache to ensure subsequent loads reflect the new record.
  static Future<void> _saveScanToHistory({
    required String userId,
    required ProductScanData scanData,
    required String ingredientsText,
  }) async {
    // Bust prefetch cache so next history load fetches fresh data including this scan
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

  // ── Domain Constants ─────────────────────────────────────────────────────

  // Maps allergen keys to ingredient keywords used for fallback text-based allergen detection
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

  // Maps allergen keys to their Arabic display names for UI presentation
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