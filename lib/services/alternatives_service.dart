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
  };

  static const Map<String, String> _arabicFallbackToCanonical = {
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
    'شوكولاتة'       : 'dairy-free chocolate',
    'سبريد شوكولاتة' : 'dairy-free chocolate-spread',
    'نوتيلا'         : 'dairy-free chocolate-spread',
    'حلوى'           : 'free-from candy',
    'جيلي'           : 'free-from candy',
    'حلاوة'          : 'free-from halawa',
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
    'بسكويت'         : 'gluten-free biscuit',
    'كوكيز'          : 'gluten-free biscuit',
    'ويفر'           : 'gluten-free biscuit',
    'كراكر'          : 'gluten-free biscuit',
    'شيبس'           : 'free-from chips',
    'بار طاقة'       : 'nut-free snack-bar',
    'فشار'           : 'free-from popcorn',
    'مايونيز'        : 'vegan mayo',
    'زبدة فول'       : 'nut-free peanut-butter-alt',
    'طحينة'          : 'sesame-free tahini-alt',
    'صوص سلطة'       : 'free-from salad-dressing',
    'صلصة صويا'      : 'gluten-free soy-sauce',
    'بيستو'          : 'nut-free pesto',
    'كريمر'          : 'dairy-free coffee-creamer',
    'مبيض'           : 'dairy-free coffee-creamer',
    'شوكولاتة ساخنة' : 'dairy-free hot-chocolate',
    'بروتين'         : 'free-from protein-shake',
    'كريمة طبخ'      : 'dairy-free cooking-cream',
    'شوربة'          : 'free-from soup',
    'صوص'            : 'free-from sauce',
  };

  // ─────────────────────────────────────────────────────────────────────────
  // INGREDIENT KEYWORDS
  // Used to filter out DB alternatives that contain an allergen the user
  // is actually allergic to (beyond the primary detected allergen).
  // ─────────────────────────────────────────────────────────────────────────
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
    required List<String> detectedAllergenTypes,
    required List<String> allUserAllergyTypes,
    required List<String> llmSuggestedAlternatives,
    required List<Map<String, dynamic>> llmRawAlternatives,
    String productTypeAr = '',
    String productCategory = '',
  }) async {
    // ── ARCHITECTURE ──────────────────────────────────────────────────────
    //
    // KEY FIX — Why the old logic broke:
    //
    // The ingredient filter was checking the alternative's ingredients against
    // ALL user allergies, including the PRIMARY detected allergen (e.g. milk).
    // This caused oat milk (which has "cream" in some variants) or soy milk
    // to be excluded even when the user only has a milk allergy.
    //
    // CORRECT LOGIC:
    //   1. Fetch DB alternatives for the detected allergen (allergy_id lookup).
    //   2. Filter by category (product type match).
    //   3. Filter by SECONDARY allergies ONLY — i.e. user allergies that are
    //      NOT the detected allergen itself.
    //      Example: user has milk + treenuts → detected = milk
    //        → secondary = [treenuts]
    //        → exclude almond milk (contains almond → treenuts keyword)
    //        → keep oat milk, soy milk, coconut milk (no treenuts keywords)
    //
    // This makes DB results DETERMINISTIC — same product, same user allergies
    // → always same list, regardless of what Gemini suggested.
    //
    // LLM suggestions are shown AFTER DB results as a supplemental section.
    // They are NOT used as a "base" for enrichment anymore — that was the
    // source of inconsistency.
    // ─────────────────────────────────────────────────────────────────────

    // ── Step 1: Compute secondary allergies ───────────────────────────────
    // These are allergens the user has that are NOT in the scanned product.
    // We only filter alternatives for these — not for the primary allergen,
    // since the alternatives ARE designed to replace that allergen.
    final Set<String> detectedSet = detectedAllergenTypes.map((s) => s.toLowerCase()).toSet();
    final List<String> secondaryAllergyTypes = allUserAllergyTypes
        .where((a) => !detectedSet.contains(a.toLowerCase()))
        .toList();
    print('🔍 Detected allergens (primary): $detectedAllergenTypes');
    print('🔍 Secondary allergies to filter by: $secondaryAllergyTypes');

    // ── Step 2: Query DB for alternatives to the PRIMARY detected allergen ─
    final List<AlternativeProduct> dbProducts = [];

    final List<int> allergyIds = detectedAllergenTypes
        .map((type) => _allergyIdMap[type.toLowerCase()])
        .whereType<int>()
        .toList();

    if (allergyIds.isNotEmpty) {
      try {
        // Collect ALL alternative_ids that match ANY detected allergen.
        // Union (not intersection) — we want alternatives safe for any of the
        // detected allergens, then let ingredient filter handle the rest.
        final Set<int> validIds = {};
        for (final allergyId in allergyIds) {
          final response = await _supabase
              .from('alternative_allergies')
              .select('alternative_id')
              .eq('allergy_id', allergyId);
          final ids = (response as List)
              .map((row) => (row['alternative_id'] as num).toInt())
              .toSet();
          print('🔍 Allergy $allergyId → ${ids.length} candidates in DB');
          validIds.addAll(ids);
        }

        if (validIds.isNotEmpty) {
          final targetCategories = _resolveTargetCategories(
            productCategory: productCategory,
            productTypeAr: productTypeAr,
          );
          print('🗂️ Target categories: $targetCategories');

          // Fetch all candidate products with ingredients for safety check
          final productsResponse = await _supabase
              .from('alternatives')
              .select('id, name_ar, name_en, brand, category, image_url, ingredients_en')
              .inFilter('id', validIds.toList());

          for (final row in productsResponse as List) {
            final map = row as Map<String, dynamic>;
            final ingredientsEn = map['ingredients_en']?.toString() ?? '';
            final categoryVal = (map['category']?.toString() ?? '').toLowerCase().trim();

            // ── Category filter ───────────────────────────────────────────
            final categoryOk = targetCategories.isEmpty ||
                targetCategories.contains(categoryVal);
            if (!categoryOk) {
              print('⛔ Skipped ${map['name_en']} — category "$categoryVal" not in $targetCategories');
              continue;
            }

            // ── Secondary allergy ingredient filter ───────────────────────
            // IMPORTANT: Only check SECONDARY allergies here.
            // Do NOT check the primary detected allergen — the product is an
            // alternative to that allergen, so its ingredients won't contain
            // it (and if they do, that's fine — e.g. soy milk has soy, and
            // soy is the alternative, not the allergy).
            bool safeForUser = true;
            for (final secondaryAllergen in secondaryAllergyTypes) {
              if (_ingredientsContainAllergen(ingredientsEn, secondaryAllergen)) {
                print('⚠️ Excluded ${map['name_en']} — ingredients contain secondary allergen: $secondaryAllergen');
                safeForUser = false;
                break;
              }
            }
            if (!safeForUser) continue;

            dbProducts.add(AlternativeProduct.fromDb(map));
          }
          print('✅ DB products after filtering: ${dbProducts.length}');
        }
      } catch (e) {
        print('❌ DB query error: $e');
      }
    }

    // ── Step 3: Build LLM suggestions list (supplemental only) ────────────
    // These appear AFTER DB results and are always shown as AI suggestions.
    // They are NOT used as a base for enrichment — this was causing
    // inconsistency because Gemini varies its suggestions each scan.
    final List<AlternativeProduct> llmProducts = [];
    if (llmRawAlternatives.isNotEmpty) {
      for (final llmAlt in llmRawAlternatives) {
        final name = llmAlt['name']?.toString() ?? '';
        if (name.isEmpty) continue;
        // Skip LLM suggestion if we already have a DB product with matching name
        final alreadyInDb = dbProducts.any((db) {
          final dbEn = db.nameEn.toLowerCase();
          final dbAr = db.nameAr.toLowerCase();
          final llmLower = name.toLowerCase();
          return dbEn.contains(llmLower) || llmLower.contains(dbEn) ||
                 dbAr.contains(llmLower) || llmLower.contains(dbAr);
        });
        if (!alreadyInDb) {
          llmProducts.add(AlternativeProduct.fromLlm(llmAlt));
        }
      }
    } else {
      // Fallback: plain name strings from LLM
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

    // ── Step 4: Combine — DB first (verified), then LLM ───────────────────
    final result = [...dbProducts, ...llmProducts];
    print('✅ Total alternatives: ${result.length} (${dbProducts.length} DB + ${llmProducts.length} LLM)');
    return result;
  }

  static List<String> _resolveTargetCategories({
    required String productCategory,
    required String productTypeAr,
  }) {
    if (productCategory.isNotEmpty) {
      final key = productCategory.toLowerCase().trim();
      final dbCategories = _canonicalCategoryMap[key];
      if (dbCategories != null && dbCategories.isNotEmpty) return dbCategories;
      print('⚠️ Unknown canonical category from Gemini: "$productCategory". '
            'Add it to _canonicalCategoryMap.');
      return [];
    }

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
