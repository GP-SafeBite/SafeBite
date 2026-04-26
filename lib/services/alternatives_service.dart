import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

class AlternativeProduct {
  final int id;
  final String nameAr;
  final String nameEn;
  final String brand;
  final String category;
  final String imageUrl;
  final bool availableInSaudi;
  final List<String> foundInStores;

  AlternativeProduct({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.brand,
    required this.category,
    required this.imageUrl,
    required this.availableInSaudi,
    this.foundInStores = const [],
  });

  factory AlternativeProduct.fromDb(Map<String, dynamic> json) {
    return AlternativeProduct(
      id: (json['id'] as num).toInt(),
      nameAr: json['name_ar']?.toString() ?? '',
      nameEn: json['name_en']?.toString() ?? '',
      brand: json['brand']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      imageUrl: json['image_url']?.toString() ?? '',
      availableInSaudi: true,
    );
  }

  factory AlternativeProduct.fromLlm(Map<String, dynamic> json) {
    return AlternativeProduct(
      id: -1,
      nameAr: json['name']?.toString() ?? '',
      nameEn: json['name']?.toString() ?? '',
      brand: '',
      category: '',
      imageUrl: '',
      availableInSaudi: json['available_in_saudi'] == true,
      foundInStores: json['found_in_stores'] is List
          ? List<String>.from(json['found_in_stores'])
          : [],
    );
  }

  factory AlternativeProduct.fromJson(Map<String, dynamic> json) {
    return AlternativeProduct(
      id: json['id'] ?? -1,
      nameAr: json['nameAr'] ?? '',
      nameEn: json['nameEn'] ?? '',
      brand: json['brand'] ?? '',
      category: json['category'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      availableInSaudi: json['availableInSaudi'] ?? false,
      foundInStores: json['foundInStores'] is List
          ? List<String>.from(json['foundInStores'])
          : [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nameAr': nameAr,
    'nameEn': nameEn,
    'brand': brand,
    'category': category,
    'imageUrl': imageUrl,
    'availableInSaudi': availableInSaudi,
    'foundInStores': foundInStores,
  };
}

class AlternativesService {
  static final _supabase = Supabase.instance.client;

  static const Map<String, int> _allergyIdMap = {
    'milk': 1, 'eggs': 2, 'gluten': 3, 'crustaceans': 4,
    'fish': 5, 'peanuts': 6, 'soybeans': 7, 'treenuts': 8,
    'celery': 9, 'mustard': 10, 'sesame': 11, 'sulfur': 12,
    'lupin': 13, 'mollusks': 14,
  };

  // ─────────────────────────────────────────────────────────────────────────
  // CANONICAL CATEGORY MAP
  // Used as a lookup for legacy Gemini responses and sibling resolution.
  // ─────────────────────────────────────────────────────────────────────────
  static const Map<String, List<String>> _canonicalCategoryMap = {
    'plant-based milk'           : ['plant-based milk'],
    'plant-based yogurt'         : ['plant-based yogurt'],
    'plant-based labneh'         : ['plant-based labneh'],
    'plant-based cheese'         : ['plant-based cheese'],
    'plant-based butter'         : ['plant-based butter'],
    'plant-based ghee'           : ['plant-based ghee'],
    'dairy-free cream'           : ['dairy-free cream'],
    'dairy-free ice cream'       : ['dairy-free ice cream'],
    'dairy-free milkshake'       : ['dairy-free milkshake'],
    'dairy-free custard'         : ['dairy-free custard'],
    'dairy-free chocolate'       : ['dairy-free chocolate'],
    'dairy-free chocolate-spread': ['dairy-free chocolate-spread'],
    'nut-free chocolate'         : ['nut-free chocolate'],
    'free-from candy'            : ['free-from candy'],
    'free-from halawa'           : ['free-from halawa'],
    'gluten-free bread'          : ['gluten-free bread'],
    'gluten-free pita'           : ['gluten-free pita'],
    'gluten-free pastry'         : ['gluten-free pastry'],
    'dairy-free cake'            : ['dairy-free cake'],
    'free-from pancake-mix'      : ['free-from pancake-mix'],
    'gluten-free pasta'          : ['gluten-free pasta'],
    'gluten-free noodles'        : ['gluten-free noodles'],
    'gluten-free cereal'         : ['gluten-free cereal'],
    'gluten-free oats'           : ['gluten-free oats'],
    'gluten-free granola'        : ['gluten-free granola'],
    'gluten-free flour-mix'      : ['gluten-free flour-mix'],
    'gluten-free biscuit'        : ['gluten-free biscuit'],
    'free-from chips'            : ['free-from chips'],
    'nut-free snack-bar'         : ['nut-free snack-bar'],
    'free-from popcorn'          : ['free-from popcorn'],
    'vegan mayo'                 : ['vegan mayo'],
    'nut-free peanut-butter-alt' : ['nut-free peanut-butter-alt'],
    'sesame-free tahini-alt'     : ['sesame-free tahini-alt'],
    'free-from salad-dressing'   : ['free-from salad-dressing'],
    'gluten-free soy-sauce'      : ['gluten-free soy-sauce'],
    'nut-free pesto'             : ['nut-free pesto'],
    'dairy-free coffee-creamer'  : ['dairy-free coffee-creamer'],
    'dairy-free hot-chocolate'   : ['dairy-free hot-chocolate'],
    'free-from protein-shake'    : ['free-from protein-shake'],
    'dairy-free cooking-cream'   : ['dairy-free cooking-cream'],
    'free-from soup'             : ['free-from soup'],
    'free-from sauce'            : ['free-from sauce'],
    'gluten-free chocolate'  : ['gluten-free chocolate'],
'gluten-free wrap'       : ['gluten-free wrap'],
'gluten-free cracker'    : ['gluten-free cracker'],
'gluten-free couscous'   : ['gluten-free couscous'],
'gluten-free waffle'     : ['gluten-free waffle'],
'gluten-free cake'       : ['gluten-free cake'],
'dairy-free whipped-cream': ['dairy-free whipped-cream'],
'free-from hummus'       : ['free-from hummus'],
'free-from date-bar'     : ['free-from date-bar'],
'free-from energy-bar'   : ['free-from energy-bar'],
'sesame-free bread'      : ['sesame-free bread'],
  };

  // ─────────────────────────────────────────────────────────────────────────
  // PRODUCT TYPE → DB CATEGORIES
  // Gemini returns a plain product type (e.g. "cereal").
  // This map translates it to all matching DB category values.
  // Separates product identification from allergen filtering completely.
  // ─────────────────────────────────────────────────────────────────────────
  static const Map<String, List<String>> _productTypeToDbCategories = {
    'milk'              : ['plant-based milk'],
    'yogurt'            : ['plant-based yogurt'],
    'labneh'            : ['plant-based labneh'],
    'cheese'            : ['plant-based cheese'],
    'butter'            : ['plant-based butter'],
    'ghee'              : ['plant-based ghee'],
    'cream'             : ['dairy-free cream'],
    'ice-cream'         : ['dairy-free ice cream'],
    'milkshake'         : ['dairy-free milkshake'],
    'custard'           : ['dairy-free custard'],
    //'chocolate'         : ['dairy-free chocolate', 'nut-free chocolate'],
    'chocolate-spread'  : ['dairy-free chocolate-spread'],
    'candy'             : ['free-from candy'],
    'halawa'            : ['free-from halawa'],
    //'bread'             : ['gluten-free bread'],
    'pita'              : ['gluten-free pita'],
    'pastry'            : ['gluten-free pastry'],
    //'cake'              : ['dairy-free cake'],
    'pancake-mix'       : ['free-from pancake-mix'],
    'pasta'             : ['gluten-free pasta'],
    'noodles'           : ['gluten-free noodles'],
    'cereal'            : ['gluten-free cereal'],
    'oats'              : ['gluten-free oats'],
    'granola'           : ['gluten-free granola'],
    'flour-mix'         : ['gluten-free flour-mix'],
    'biscuit'           : ['gluten-free biscuit'],
    'chips'             : ['free-from chips'],
    'snack-bar'         : ['nut-free snack-bar'],
    'popcorn'           : ['free-from popcorn'],
    'mayo'              : ['vegan mayo'],
    'peanut-butter-alt' : ['nut-free peanut-butter-alt'],
    'tahini-alt'        : ['sesame-free tahini-alt'],
    'salad-dressing'    : ['free-from salad-dressing'],
    'soy-sauce'         : ['gluten-free soy-sauce'],
    'pesto'             : ['nut-free pesto'],
    'sauce'             : ['free-from sauce'],
    'coffee-creamer'    : ['dairy-free coffee-creamer'],
    'hot-chocolate'     : ['dairy-free hot-chocolate'],
    'protein-shake'     : ['free-from protein-shake'],
    'cooking-cream'     : ['dairy-free cooking-cream'],
    'soup'              : ['free-from soup'],
    'chocolate' : ['dairy-free chocolate', 'nut-free chocolate', 'gluten-free chocolate'],
'cake'      : ['dairy-free cake', 'gluten-free cake'],
'bread'     : ['gluten-free bread', 'sesame-free bread'],
// add new ones:
'wrap'          : ['gluten-free wrap'],
'cracker'       : ['gluten-free cracker'],
'couscous'      : ['gluten-free couscous'],
'waffle'        : ['gluten-free waffle'],
'whipped-cream' : ['dairy-free whipped-cream'],
'hummus'        : ['free-from hummus'],
'date-bar'      : ['free-from date-bar'],
'energy-bar'    : ['free-from energy-bar'],
  };

  // ─────────────────────────────────────────────────────────────────────────
  // ARABIC FALLBACK MAP
  // Used when Gemini returns empty product_category.
  // Maps Arabic keyword → plain product type (same values as _productTypeToDbCategories keys).
  // FIX: values are now plain types ('milk', 'cereal') not old canonical strings
  //      ('plant-based milk', 'gluten-free cereal') so they route through
  //      _productTypeToDbCategories consistently with the primary path.
  // ─────────────────────────────────────────────────────────────────────────
  static const Map<String, String> _arabicFallbackToCanonical = {
    'حليب'           : 'milk',
    'مشروب حليب'     : 'milk',
    'زبادي'          : 'yogurt',
    'لبن رائب'        : 'yogurt',
    'لبن'            : 'yogurt',
    'لبنة'           : 'labneh',
    'جبن'            : 'cheese',
    'جبنة'           : 'cheese',
    'زبدة'           : 'butter',
    'مارجرين'        : 'butter',
    'سمن'            : 'ghee',
    'كريمة'          : 'cream',
    'كريم'           : 'cream',
    'آيس كريم'       : 'ice-cream',
    'ايس كريم'       : 'ice-cream',
    'جيلاتو'         : 'ice-cream',
    'ميلك شيك'       : 'milkshake',
    'كاسترد'         : 'custard',
    'شوكولاتة'       : 'chocolate',
    'سبريد شوكولاتة' : 'chocolate-spread',
    'نوتيلا'         : 'chocolate-spread',
    'حلوى'           : 'candy',
    'جيلي'           : 'candy',
    'حلاوة'          : 'halawa',
    'خبز'            : 'bread',
    'توست'           : 'bread',
    'باغيت'          : 'bread',
    'صمون'           : 'bread',
    'خبز عربي'       : 'pita',
    'خبز مسطح'       : 'pita',
    'كرواسان'        : 'pastry',
    'باستري'         : 'pastry',
    'كيك'            : 'cake',
    'مافن'           : 'cake',
    'كب كيك'         : 'cake',
    'براونيز'        : 'cake',
    'بان كيك'        : 'pancake-mix',
    'وافل'           : 'pancake-mix',
    'معكرونة'        : 'pasta',
    'باستا'          : 'pasta',
    'نودلز'          : 'noodles',
    'شعرية'          : 'noodles',
    'حبوب إفطار'     : 'cereal',
    'كورن فليكس'     : 'cereal',
    'مسلي'           : 'cereal',
    'شوفان'          : 'oats',
    'غرانولا'        : 'granola',
    'دقيق'           : 'flour-mix',
    'بسكويت'         : 'biscuit',
    'كوكيز'          : 'biscuit',
    'ويفر'           : 'biscuit',
    'كراكر'          : 'biscuit',
    'شيبس'           : 'chips',
    'بار طاقة'       : 'snack-bar',
    'فشار'           : 'popcorn',
    'مايونيز'        : 'mayo',
    'زبدة فول'       : 'peanut-butter-alt',
    'طحينة'          : 'tahini-alt',
    'صوص سلطة'       : 'salad-dressing',
    'صلصة صويا'      : 'soy-sauce',
    'بيستو'          : 'pesto',
    'كريمر'          : 'coffee-creamer',
    'مبيض'           : 'coffee-creamer',
    'شوكولاتة ساخنة' : 'hot-chocolate',
    'بروتين'         : 'protein-shake',
   'كريمة طبخ'      : 'cooking-cream',
    'شوربة'          : 'soup',
    'صوص'            : 'sauce',
    'شوكولاتة خالية من الجلوتين' : 'chocolate',
'تورتيلا'    : 'wrap',
'راب'        : 'wrap',
'كريمة مخفوقة': 'whipped-cream',
'حمص'        : 'hummus',
'بار تمر'    : 'date-bar',
'تمر'        : 'date-bar',
  };

  // ─────────────────────────────────────────────────────────────────────────
  // ARCHITECTURE SUMMARY
  // ─────────────────────────────────────────────────────────────────────────
  //
  // Q1: What type of product is this?
  //     Gemini returns plain type: "cereal", "milk", "chocolate"
  //     (ignores user allergies — pure product identification)
  //
  // Q2: Which DB categories match this type?
  //     _productTypeToDbCategories["cereal"] → ['gluten-free cereal']
  //     _productTypeToDbCategories["chocolate"] → ['dairy-free chocolate', 'nut-free chocolate']
  //
  // Q3: Is each DB result safe for this user?
  //     allergens_present [8] ∩ user_allergy_ids [1, 8] = [8] → EXCLUDED
  //     allergens_present []  ∩ user_allergy_ids [1, 8] = []  → SAFE
  //
  // No junction table. No keyword matching. No text parsing.
  // Pure integer set intersection — deterministic and language-independent.
  // ─────────────────────────────────────────────────────────────────────────

  static Future<List<AlternativeProduct>> getAlternatives({
    required List<String> allUserAllergyTypes,
    required List<String> llmSuggestedAlternatives,
    required List<Map<String, dynamic>> llmRawAlternatives,
    String productTypeAr = '',
    String productCategory = '',
    List<String> detectedAllergenTypes = const [],
  }) async {

    print('👤 User profile allergies: $allUserAllergyTypes');

    // ── Step 1: Resolve target DB categories from product type ─────────────
    final targetCategories = _resolveTargetCategories(
      productCategory: productCategory,
      productTypeAr: productTypeAr,
    );
    print('🗂️ Target categories: $targetCategories');

    // ── Step 2: Convert user allergy strings to ids ────────────────────────
    final List<int> userAllergyIds = allUserAllergyTypes
        .map((type) => _allergyIdMap[type.toLowerCase()])
        .whereType<int>()
        .toList();
    print('🔍 User allergy ids: $userAllergyIds');

    final List<AlternativeProduct> dbProducts = [];

    try {
  // ── Step 3: Direct category query — no junction table ─────────────────
  if (targetCategories.isEmpty) {
    print('⚠️ No target categories — skipping DB query entirely.');
  } else {
    final productsResponse = await _supabase
        .from('alternatives')
        .select('id, name_ar, name_en, brand, category, image_url, allergens_present')
        .inFilter('category', targetCategories);

    // ── Step 4: Safety filter — pure integer intersection ─────────────────
    for (final row in productsResponse as List) {
      final map = row as Map<String, dynamic>;
      final List<int> productAllergenIds = _parseAllergensPresent(map['allergens_present']);

      final bool safeForUser = userAllergyIds.isEmpty ||
          !userAllergyIds.any((id) => productAllergenIds.contains(id));

      if (!safeForUser) {
        final conflicts = userAllergyIds
            .where((id) => productAllergenIds.contains(id))
            .toList();
        print('⚠️ Excluded ${map['name_en']} — allergens_present conflicts: $conflicts');
        continue;
      }

      dbProducts.add(AlternativeProduct.fromDb(map));
    }
    print('✅ DB products after safety filter: ${dbProducts.length}');
  }
} catch (e) {
  print('❌ DB query error: $e');
}

    // ── Step 4b: Arabic fallback retry — if DB returned 0 results ─────────
    // Handles cases where Gemini returned empty/wrong product_category
    // but product_type_ar contains a recognisable Arabic keyword.
    // Also handles spelling variants: "زبادى" / "زبادة" still contain "زبادي"
    // because _arabicFallbackToCanonical uses contains() not exact match.
    if (dbProducts.isEmpty && productTypeAr.isNotEmpty&&targetCategories.isEmpty) {
      print('🔄 DB returned 0 — retrying with Arabic fallback for "$productTypeAr"');
      try {
        final fallbackCategories = _resolveFromArabicOnly(productTypeAr);
        if (fallbackCategories.isNotEmpty) {
          print('🗂️ Arabic fallback retry categories: $fallbackCategories');
          final fallbackResponse = await _supabase
              .from('alternatives')
              .select('id, name_ar, name_en, brand, category, image_url, allergens_present')
              .inFilter('category', fallbackCategories);

          for (final row in fallbackResponse as List) {
            final map = row as Map<String, dynamic>;
            final List<int> productAllergenIds = _parseAllergensPresent(map['allergens_present']);
            final bool safeForUser = userAllergyIds.isEmpty ||
                !userAllergyIds.any((id) => productAllergenIds.contains(id));
            if (!safeForUser) {
              final conflicts = userAllergyIds
                  .where((id) => productAllergenIds.contains(id))
                  .toList();
              print('⚠️ Fallback excluded ${map['name_en']} — conflicts: $conflicts');
              continue;
            }
            dbProducts.add(AlternativeProduct.fromDb(map));
          }
          print('✅ DB products after Arabic fallback retry: ${dbProducts.length}');
        } else {
          print('⚠️ Arabic fallback found no matching categories for "$productTypeAr"');
        }
      } catch (e) {
        print('❌ Arabic fallback retry error: $e');
      }
    }

    // ── Step 5: LLM suggestions — supplemental display only ───────────────
    final List<AlternativeProduct> llmProducts = [];
    if (llmRawAlternatives.isNotEmpty) {
      for (final llmAlt in llmRawAlternatives) {
        final name = llmAlt['name']?.toString() ?? '';
        if (name.isEmpty) continue;
        final alreadyInDb = dbProducts.any((db) {
          final dbEn = db.nameEn.toLowerCase();
          final dbAr = db.nameAr.toLowerCase();
          final llmLower = name.toLowerCase();
          return dbEn.contains(llmLower) || llmLower.contains(dbEn) ||
                 dbAr.contains(llmLower) || llmLower.contains(dbAr);
        });
        if (!alreadyInDb) llmProducts.add(AlternativeProduct.fromLlm(llmAlt));
      }
    } else {
      for (final suggestion in llmSuggestedAlternatives) {
        if (suggestion.isEmpty) continue;
        final alreadyInDb = dbProducts.any((db) {
          final dbEn = db.nameEn.toLowerCase();
          final llmLower = suggestion.toLowerCase();
          return dbEn.contains(llmLower) || llmLower.contains(dbEn);
        });
        if (!alreadyInDb) {
          llmProducts.add(AlternativeProduct(
            id: -1, nameAr: suggestion, nameEn: suggestion,
            brand: '', category: '', imageUrl: '', availableInSaudi: false,
          ));
        }
      }
    }
    print('🤖 LLM supplemental suggestions: ${llmProducts.length}');

    final result = [...dbProducts, ...llmProducts];
    print('✅ Total alternatives: ${result.length} (${dbProducts.length} DB + ${llmProducts.length} LLM)');
    return result;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CATEGORY RESOLUTION
  // Priority:
  //   1. Plain type from Gemini ("cereal") → _productTypeToDbCategories
  //   2. Legacy type from Gemini ("gluten-free cereal") → _findSiblingCategories
  //   3. Arabic fallback from product_type_ar → _arabicFallbackToCanonical
  //      → plain type → _productTypeToDbCategories  (FIX: now consistent)
  // ─────────────────────────────────────────────────────────────────────────
  static List<String> _resolveTargetCategories({
    required String productCategory,
    required String productTypeAr,
  }) {
    if (productCategory.isNotEmpty) {
      final key = productCategory.toLowerCase().trim();

      // 1. Plain product type (new Gemini format: "cereal", "milk" etc.)
      if (_productTypeToDbCategories.containsKey(key)) {
        final categories = _productTypeToDbCategories[key]!;
        print('🗂️ Resolved plain product type "$key" → $categories');
        return categories;
      }

      // 2. Legacy canonical category (old Gemini format: "gluten-free cereal")
      //    Find all DB categories sharing the same base product type.
      if (_canonicalCategoryMap.containsKey(key)) {
        final siblings = _findSiblingCategories(key);
        print('🗂️ Resolved legacy category "$key" → siblings $siblings');
        return siblings;
      }

      print('⚠️ Unknown category from Gemini: "$productCategory".');
      return [];
    }

    // 3. Arabic fallback — now correctly routes through _productTypeToDbCategories
    //    FIX: _arabicFallbackToCanonical values are now plain types ('milk', 'cereal')
    //         so this path is consistent with path 1 above.
    if (productTypeAr.isNotEmpty) {
      for (final entry in _arabicFallbackToCanonical.entries) {
        if (productTypeAr.contains(entry.key)) {
          final plainType = entry.value; // e.g. 'milk', 'cereal'
          if (_productTypeToDbCategories.containsKey(plainType)) {
            final categories = _productTypeToDbCategories[plainType]!;
            print('🗂️ Resolved Arabic fallback "${entry.key}" → "$plainType" → $categories');
            return categories;
          }
        }
      }
    }

    return [];
  }

  /// Same as the Arabic path in _resolveTargetCategories but standalone,
  /// so Step 4b can call it independently as a retry without re-running Gemini.
  static List<String> _resolveFromArabicOnly(String productTypeAr) {
    for (final entry in _arabicFallbackToCanonical.entries) {
      if (productTypeAr.contains(entry.key)) {
        final plainType = entry.value;
        if (_productTypeToDbCategories.containsKey(plainType)) {
          return _productTypeToDbCategories[plainType]!;
        }
      }
    }
    return [];
  }

  /// Returns all canonical DB categories sharing the same base product type.
  /// Strips allergen-prefix, then matches every category with the same base noun.
  /// Automatically includes new categories added to _canonicalCategoryMap.
  ///
  /// Examples:
  ///   "gluten-free cereal"   → base "cereal"    → ["gluten-free cereal"]
  ///   "dairy-free chocolate" → base "chocolate" → ["dairy-free chocolate", "nut-free chocolate"]
  ///   "plant-based milk"     → base "milk"      → ["plant-based milk"]
  static List<String> _findSiblingCategories(String category) {
    final baseType = _extractBaseProductType(category);
    if (baseType.isEmpty) return [category];

    final siblings = _canonicalCategoryMap.keys
        .where((k) => _extractBaseProductType(k) == baseType)
        .toList();

    return siblings.isNotEmpty ? siblings : [category];
  }

  /// Strips allergen-prefix from a category string to get the base product type.
  ///   "gluten-free cereal"   → "cereal"
  ///   "dairy-free chocolate" → "chocolate"
  ///   "plant-based milk"     → "milk"
  ///   "nut-free snack-bar"   → "snack-bar"
  static String _extractBaseProductType(String category) {
    const prefixes = [
      'gluten-free ', 'dairy-free ', 'plant-based ',
      'nut-free ', 'free-from ', 'sesame-free ', 'vegan ',
    ];
    final lower = category.toLowerCase().trim();
    for (final prefix in prefixes) {
      if (lower.startsWith(prefix)) {
        return lower.substring(prefix.length).trim();
      }
    }
    return lower;
  }

  /// Parses allergens_present jsonb column into List<int>.
  /// Handles null, empty, List, and String representations safely.
  static List<int> _parseAllergensPresent(dynamic value) {
    if (value == null) return [];
    try {
      if (value is List) {
        return value.map((e) => (e as num).toInt()).toList();
      }
      if (value is String) {
        final decoded = jsonDecode(value);
        if (decoded is List) {
          return decoded.map((e) => (e as num).toInt()).toList();
        }
      }
    } catch (e) {
      print('⚠️ Failed to parse allergens_present: $value — $e');
    }
    return [];
  }

  static List<AlternativeProduct> fromJsonList(String json) {
    try {
      final list = jsonDecode(json) as List;
      return list.map((e) => AlternativeProduct.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static String toJsonList(List<AlternativeProduct> products) {
    return jsonEncode(products.map((p) => p.toJson()).toList());
  }
}