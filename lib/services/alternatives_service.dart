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
  // ─────────────────────────────────────────────────────────────────────────
  // Gemini always returns one of the fixed canonical KEYS below (enforced by
  // the prompt). The VALUE is the list of category strings stored in your
  // `alternatives` DB table.
  //
  // HOW TO ADD A NEW PRODUCT TYPE — only 3 steps:
  //   1. Add the canonical key to the Gemini prompt (product_category section).
  //   2. Add a row here:  'canonical-key' : ['your-db-category-value']
  //   3. Insert alternative products in DB with that category value.
  //   No other code changes needed.
  //
  // WHY A LIST per key?
  //   Lets you group multiple DB categories under one scan type.
  //   e.g. if you store both 'nut-cheese' and 'soy-cheese' and want both to
  //   appear when user scans any cheese product:
  //     'plant-based cheese' : ['nut-cheese', 'soy-cheese']
  // ─────────────────────────────────────────────────────────────────────────
  static const Map<String, List<String>> _canonicalCategoryMap = {
    // ════════════════════════════════════════════════════════════════════════
    // KEY  = exact string Gemini returns in product_category field
    //        (must also be listed in the Gemini prompt's product_category block)
    // VALUE = list of category strings stored in your alternatives DB table
    //         (use multiple values to group sub-types under one scan type)
    // ════════════════════════════════════════════════════════════════════════

    // ── DAIRY & MILK PRODUCTS ─────────────────────────────────────────────
    'plant-based milk'           : ['plant-based milk'],        // حليب سائل (أبقار، ماعز، كامل الدسم...)
    'plant-based yogurt'         : ['plant-based yogurt'],      // زبادي / لبن رائب
    'plant-based labneh'         : ['plant-based labneh'],      // لبنة
    'plant-based cheese'         : ['plant-based cheese'],      // جبن (شيدر، موزاريلا، كريم چيز...)
    'plant-based butter'         : ['plant-based butter'],      // زبدة / مارجرين
    'plant-based ghee'           : ['plant-based ghee'],        // سمن
    'dairy-free cream'           : ['dairy-free cream'],        // كريمة طبخ / كريمة خفق
    'dairy-free ice cream'       : ['dairy-free ice cream'],    // آيس كريم / جيلاتو
    'dairy-free milkshake'       : ['dairy-free milkshake'],    // ميلك شيك / مشروب حليب مُنكَّه
    'dairy-free custard'         : ['dairy-free custard'],      // كاسترد / كريم بروليه

    // ── CHOCOLATE & SWEETS ────────────────────────────────────────────────
    'dairy-free chocolate'       : ['dairy-free chocolate'],    // شوكولاتة ألواح
    'dairy-free chocolate-spread': ['dairy-free chocolate-spread'], // سبريد شوكولاتة (نوتيلا...)
    'nut-free chocolate'         : ['nut-free chocolate'],      // شوكولاتة بدون مكسرات
    'free-from candy'            : ['free-from candy'],         // حلوى / ماصات / جيلي
    'free-from halawa'           : ['free-from halawa'],        // حلاوة طحينية

    // ── BAKERY ────────────────────────────────────────────────────────────
    'gluten-free bread'          : ['gluten-free bread'],       // خبز / توست / باغيت / صمون
    'gluten-free pita'           : ['gluten-free pita'],        // خبز عربي / خبز مسطح
    'gluten-free pastry'         : ['gluten-free pastry'],      // كرواسان / دانيش / باستري
    'dairy-free cake'            : ['dairy-free cake'],         // كيك / مافن / كب كيك / براونيز
    'free-from pancake-mix'      : ['free-from pancake-mix'],  // خليط بان كيك / وافل

    // ── PASTA, GRAINS & CEREALS ───────────────────────────────────────────
    'gluten-free pasta'          : ['gluten-free pasta'],       // معكرونة / باستا
    'gluten-free noodles'        : ['gluten-free noodles'],     // نودلز / شعرية
    'gluten-free cereal'         : ['gluten-free cereal'],      // حبوب إفطار / كورن فليكس / مسلي
    'gluten-free oats'           : ['gluten-free oats'],        // شوفان
    'gluten-free granola'        : ['gluten-free granola'],     // غرانولا
    'gluten-free flour-mix'      : ['gluten-free flour-mix'],   // دقيق / خليط خبيز

    // ── BISCUITS & SNACKS ─────────────────────────────────────────────────
    'gluten-free biscuit'        : ['gluten-free biscuit'],     // بسكويت / كوكيز / ويفر / كراكر
    'free-from chips'            : ['free-from chips'],         // شيبس / كرسبي
    'nut-free snack-bar'         : ['nut-free snack-bar'],      // بار طاقة / بار حبوب
    'free-from popcorn'          : ['free-from popcorn'],       // فشار

    // ── SPREADS & CONDIMENTS ──────────────────────────────────────────────
    'vegan mayo'                 : ['vegan mayo'],              // مايونيز
    'nut-free peanut-butter-alt' : ['nut-free peanut-butter-alt'], // زبدة فول سوداني / بديل بدون مكسرات
    'sesame-free tahini-alt'     : ['sesame-free tahini-alt'],  // طحينة / بديل بدون سمسم
    'free-from salad-dressing'   : ['free-from salad-dressing'],// صوص سلطة / ديب
    'gluten-free soy-sauce'      : ['gluten-free soy-sauce'],   // صلصة صويا / تاماري / كوكونت أمينوز
    'nut-free pesto'             : ['nut-free pesto'],          // بيستو بدون مكسرات

    // ── BEVERAGES ─────────────────────────────────────────────────────────
    'dairy-free coffee-creamer'  : ['dairy-free coffee-creamer'], // مبيض قهوة / كريمر
    'dairy-free hot-chocolate'   : ['dairy-free hot-chocolate'],  // مسحوق شوكولاتة ساخنة
    'free-from protein-shake'    : ['free-from protein-shake'],   // بروتين / ميل ريبليسمنت

    // ── SAUCES & COOKING ──────────────────────────────────────────────────
    'dairy-free cooking-cream'   : ['dairy-free cooking-cream'], // كريمة طبخ
    'free-from soup'             : ['free-from soup'],           // شوربة جاهزة / مركز شوربة
    'free-from sauce'            : ['free-from sauce'],          // صوص جاهز (بيتزا، مكرونة...)

    // ── ADD NEW ROWS HERE ─────────────────────────────────────────────────
    // Pattern: 'canonical-key' : ['db-category-value']
    // Then add the key to the Gemini prompt and insert DB rows with that category.
  };

  // Arabic fallback — used ONLY when Gemini returns an empty product_category.
  // Maps a keyword found anywhere in product_type_ar → the canonical key above.
  static const Map<String, String> _arabicFallbackToCanonical = {
    // ── Milk & Dairy ──────────────────────────────────────────────────────
    'حليب'           : 'plant-based milk',
    'مشروب حليب'     : 'plant-based milk',
    'زبادي'          : 'plant-based yogurt',
    'لبن رائب'        : 'plant-based yogurt',
    'لبن'            : 'plant-based yogurt',
    'لبنة'           : 'plant-based labneh',
    'جبن'            : 'plant-based cheese',
    'جبنة'           : 'plant-based cheese',
    'زبدة'           : 'plant-based butter',
    'مارجرين'        : 'plant-based butter',
    'سمن'            : 'plant-based ghee',
    'كريمة'          : 'dairy-free cream',
    'كريم'           : 'dairy-free cream',
    'آيس كريم'       : 'dairy-free ice cream',
    'ايس كريم'       : 'dairy-free ice cream',
    'جيلاتو'         : 'dairy-free ice cream',
    'ميلك شيك'       : 'dairy-free milkshake',
    'كاسترد'         : 'dairy-free custard',
    // ── Chocolate & Sweets ────────────────────────────────────────────────
    'شوكولاتة'       : 'dairy-free chocolate',
    'سبريد شوكولاتة' : 'dairy-free chocolate-spread',
    'نوتيلا'         : 'dairy-free chocolate-spread',
    'حلوى'           : 'free-from candy',
    'جيلي'           : 'free-from candy',
    'حلاوة'          : 'free-from halawa',
    // ── Bakery ────────────────────────────────────────────────────────────
    'خبز'            : 'gluten-free bread',
    'توست'           : 'gluten-free bread',
    'باغيت'          : 'gluten-free bread',
    'صمون'           : 'gluten-free bread',
    'خبز عربي'       : 'gluten-free pita',
    'خبز مسطح'       : 'gluten-free pita',
    'كرواسان'        : 'gluten-free pastry',
    'باستري'         : 'gluten-free pastry',
    'كيك'            : 'dairy-free cake',
    'مافن'           : 'dairy-free cake',
    'كب كيك'         : 'dairy-free cake',
    'براونيز'        : 'dairy-free cake',
    'بان كيك'        : 'free-from pancake-mix',
    'وافل'           : 'free-from pancake-mix',
    // ── Pasta & Grains ────────────────────────────────────────────────────
    'معكرونة'        : 'gluten-free pasta',
    'باستا'          : 'gluten-free pasta',
    'نودلز'          : 'gluten-free noodles',
    'شعرية'          : 'gluten-free noodles',
    'حبوب إفطار'     : 'gluten-free cereal',
    'كورن فليكس'     : 'gluten-free cereal',
    'مسلي'           : 'gluten-free cereal',
    'شوفان'          : 'gluten-free oats',
    'غرانولا'        : 'gluten-free granola',
    'دقيق'           : 'gluten-free flour-mix',
    // ── Biscuits & Snacks ─────────────────────────────────────────────────
    'بسكويت'         : 'gluten-free biscuit',
    'كوكيز'          : 'gluten-free biscuit',
    'ويفر'           : 'gluten-free biscuit',
    'كراكر'          : 'gluten-free biscuit',
    'شيبس'           : 'free-from chips',
    'بار طاقة'       : 'nut-free snack-bar',
    'فشار'           : 'free-from popcorn',
    // ── Spreads & Condiments ──────────────────────────────────────────────
    'مايونيز'        : 'vegan mayo',
    'زبدة فول'       : 'nut-free peanut-butter-alt',
    'طحينة'          : 'sesame-free tahini-alt',
    'صوص سلطة'       : 'free-from salad-dressing',
    'صلصة صويا'      : 'gluten-free soy-sauce',
    'بيستو'          : 'nut-free pesto',
    // ── Beverages ─────────────────────────────────────────────────────────
    'كريمر'          : 'dairy-free coffee-creamer',
    'مبيض'           : 'dairy-free coffee-creamer',
    'شوكولاتة ساخنة' : 'dairy-free hot-chocolate',
    'بروتين'         : 'free-from protein-shake',
    // ── Sauces & Cooking ──────────────────────────────────────────────────
    'كريمة طبخ'      : 'dairy-free cooking-cream',
    'شوربة'          : 'free-from soup',
    'صوص'            : 'free-from sauce',
  };

  // Keywords to check product ingredients against user's secondary allergies.
  // Used to filter out DB alternatives that contain an allergen the user has,
  // even if that allergen isn't recorded in alternative_allergies table.
  static const Map<String, List<String>> _ingredientKeywords = {
    'milk'        : ['milk', 'dairy', 'lactose', 'whey', 'casein', 'cream', 'butter', 'cheese', 'yogurt'],
    'eggs'        : ['egg', 'albumin', 'mayonnaise'],
    'gluten'      : ['wheat', 'gluten', 'barley', 'rye', 'flour', 'malt', 'oat'],
    'fish'        : ['fish', 'salmon', 'tuna', 'cod', 'anchovy'],
    'peanuts'     : ['peanut', 'groundnut', 'arachis'],
    'soybeans'    : ['soy', 'soya', 'tofu', 'edamame', 'miso', 'tempeh'],
    'treenuts'    : ['almond', 'cashew', 'walnut', 'pistachio', 'hazelnut',
                     'pecan', 'macadamia', 'brazil nut', 'pine nut', 'chestnut'],
    'sesame'      : ['sesame', 'tahini', 'til', 'gingelly'],
    'crustaceans' : ['shrimp', 'crab', 'lobster', 'prawn', 'crayfish'],
    'celery'      : ['celery', 'celeriac'],
    'mustard'     : ['mustard'],
    'sulfur'      : ['sulphite', 'sulfite', 'e220', 'e221', 'e222', 'e223', 'e224', 'e225', 'e226', 'e227', 'e228'],
    'lupin'       : ['lupin', 'lupine'],
    'mollusks'    : ['mollusc', 'squid', 'oyster', 'mussel', 'clam', 'scallop'],
  };

  /// Returns true if the product's ingredients contain any keyword
  /// for the given allergen type.
  static bool _ingredientsContainAllergen(String ingredientsEn, String allergenType) {
    final lower = ingredientsEn.toLowerCase();
    final keywords = _ingredientKeywords[allergenType.toLowerCase()] ?? [];
    return keywords.any((k) => lower.contains(k));
  }

  static Future<List<AlternativeProduct>> getAlternatives({
    // allergens detected IN the scanned product — used for DB lookup only
    required List<String> detectedAllergenTypes,
    // ALL user allergies — used to filter out unsafe DB results via ingredients
    required List<String> allUserAllergyTypes,
    required List<String> llmSuggestedAlternatives,
    required List<Map<String, dynamic>> llmRawAlternatives,
    String productTypeAr = '',
    String productCategory = '',
  }) async {
    // ── ARCHITECTURE ──────────────────────────────────────────────────────
    // PROBLEM THIS SOLVES:
    //   alternative_allergies only stores the PRIMARY allergen each product
    //   is an alternative for (e.g. allergy_id=1 for all plant-based milks).
    //   It does NOT list every allergen each product is safe for.
    //   So intersection across all user allergies always returns empty when
    //   user has multiple allergies (e.g. milk + nuts → allergy_id=8 has no
    //   rows → intersection = {}).
    //
    // SOLUTION:
    //   1. DB query uses ONLY detectedAllergenTypes (allergens in the scanned
    //      product) — this always has rows in alternative_allergies.
    //   2. After getting DB candidates, filter them by checking ingredients_en
    //      against ALL user allergies. This catches e.g. almond milk for a
    //      nut-allergic user without needing DB rows for every allergen.
    //   3. LLM suggestions are always shown as base — no empty states ever.
    //   4. DB results ENRICH LLM suggestions (add brand, image, verified flag).
    // ─────────────────────────────────────────────────────────────────────

    // Step 1: LLM suggestions are the guaranteed base list.
    final List<AlternativeProduct> result = [];
    if (llmRawAlternatives.isNotEmpty) {
      for (final llmAlt in llmRawAlternatives) {
        final name = llmAlt['name']?.toString() ?? '';
        if (name.isNotEmpty) result.add(AlternativeProduct.fromLlm(llmAlt));
      }
    } else {
      for (final suggestion in llmSuggestedAlternatives) {
        if (suggestion.isNotEmpty) {
          result.add(AlternativeProduct(
            id: -1, nameAr: suggestion, nameEn: suggestion,
            brand: '', category: '', imageUrl: '', availableInSaudi: false,
          ));
        }
      }
    }
    print('🤖 LLM base suggestions: ${result.length}');

    // Step 2: Query DB using ONLY the detected allergen types
    // (guaranteed to have rows in alternative_allergies).
    final List<AlternativeProduct> dbProducts = [];
    final List<int> allergyIds = detectedAllergenTypes
        .map((type) => _allergyIdMap[type.toLowerCase()])
        .whereType<int>()
        .toList();

    if (allergyIds.isNotEmpty) {
      try {
        Set<int>? validIds;
        for (final allergyId in allergyIds) {
          final response = await _supabase
              .from('alternative_allergies')
              .select('alternative_id')
              .eq('allergy_id', allergyId);
          final ids = (response as List)
              .map((row) => (row['alternative_id'] as num).toInt())
              .toSet();
          print('🔍 Allergy $allergyId → ${ids.length} candidates in DB');
          validIds = validIds == null ? ids : validIds.intersection(ids);
        }

        if (validIds != null && validIds.isNotEmpty) {
          final targetCategories = _resolveTargetCategories(
            productCategory: productCategory,
            productTypeAr: productTypeAr,
          );
          print('🗂️ Target categories: $targetCategories');

          // Fetch candidates — include ingredients_en for secondary allergy check
          final productsResponse = await _supabase
              .from('alternatives')
              .select('id, name_ar, name_en, brand, category, image_url, ingredients_en')
              .inFilter('id', validIds.toList());

          for (final row in productsResponse as List) {
            final map = row as Map<String, dynamic>;
            final ingredientsEn = map['ingredients_en']?.toString() ?? '';
            final categoryVal  = (map['category']?.toString() ?? '').toLowerCase().trim();

            // ── Category filter ───────────────────────────────────────────
            final categoryOk = targetCategories.isEmpty ||
                targetCategories.contains(categoryVal);
            if (!categoryOk) {
              print('⛔ Skipped ${map['name_en']} — category "$categoryVal" not in $targetCategories');
              continue;
            }

            // ── Ingredient safety filter (Issue 1 fix) ────────────────────
            // Check the product's own ingredients against ALL user allergies.
            // This is how we exclude almond milk for nut-allergic users even
            // though alternative_allergies has no treenuts rows.
            bool safeForUser = true;
            for (final userAllergyType in allUserAllergyTypes) {
              if (_ingredientsContainAllergen(ingredientsEn, userAllergyType)) {
                print('⚠️ Excluded ${map['name_en']} — ingredients contain $userAllergyType');
                safeForUser = false;
                break;
              }
            }
            if (!safeForUser) continue;

            dbProducts.add(AlternativeProduct.fromDb(map));
          }
          print('✅ DB products after category + ingredient filter: ${dbProducts.length}');
        }
      } catch (e) {
        print('❌ DB query error: $e');
      }
    }

    // Step 3: Enrich LLM results with DB data where names match.
    final Set<int> usedDbIds = {};
    for (int i = 0; i < result.length; i++) {
      final llmName = result[i].nameEn.toLowerCase().trim();
      final matched = dbProducts.where((db) {
        if (usedDbIds.contains(db.id)) return false;
        final dbEn = db.nameEn.toLowerCase().trim();
        final dbAr = db.nameAr.toLowerCase().trim();
        return dbEn.contains(llmName) || llmName.contains(dbEn) ||
               dbAr.contains(llmName) || llmName.contains(dbAr);
      }).firstOrNull;

      if (matched != null) {
        result[i] = matched;
        usedDbIds.add(matched.id);
        print('🔗 Enriched "${result[i].nameEn}" with DB data');
      }
    }

    // Step 4: Prepend DB products not matched by any LLM suggestion.
    final unmatched = dbProducts.where((db) => !usedDbIds.contains(db.id)).toList();
    if (unmatched.isNotEmpty) {
      result.insertAll(0, unmatched);
      print('➕ ${unmatched.length} extra DB products added');
    }

    print('✅ Total alternatives: ${result.length}');
    return result;
  }

  /// Resolves which DB category values to filter by.
  /// Primary:  Gemini canonical key → _canonicalCategoryMap → DB values.
  /// Fallback: Arabic keyword in product_type_ar → canonical key → DB values.
  /// Returns [] if neither source produces a result (caller shows no DB rows).
  static List<String> _resolveTargetCategories({
    required String productCategory,
    required String productTypeAr,
  }) {
    // Primary: use Gemini's canonical category key directly.
    // Lowercased on both sides so casing differences never cause silent misses.
    if (productCategory.isNotEmpty) {
      final key = productCategory.toLowerCase().trim();
      final dbCategories = _canonicalCategoryMap[key];
      if (dbCategories != null && dbCategories.isNotEmpty) return dbCategories;
      print('⚠️ Unknown canonical category from Gemini: "$productCategory". '
            'Add it to _canonicalCategoryMap.');
      return [];
    }

    // Fallback: derive canonical key from Arabic product type string.
    if (productTypeAr.isNotEmpty) {
      for (final entry in _arabicFallbackToCanonical.entries) {
        if (productTypeAr.contains(entry.key)) {
          return _canonicalCategoryMap[entry.value] ?? [];
        }
      }
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