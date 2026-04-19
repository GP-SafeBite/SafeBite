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

  // Maps plain product types (returned by Gemini) to all matching DB categories.
  // This decouples product identification from allergen filtering.
  // Gemini always returns e.g. "cereal" regardless of the user's allergy,
  // and this table handles the DB category translation deterministically.
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
    'chocolate'         : ['dairy-free chocolate', 'nut-free chocolate'],
    'chocolate-spread'  : ['dairy-free chocolate-spread'],
    'candy'             : ['free-from candy'],
    'halawa'            : ['free-from halawa'],
    'bread'             : ['gluten-free bread'],
    'pita'              : ['gluten-free pita'],
    'pastry'            : ['gluten-free pastry'],
    'cake'              : ['dairy-free cake'],
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
  };

  // ─────────────────────────────────────────────────────────────────────────
  // NEW ARCHITECTURE — allergens_present column approach
  // ─────────────────────────────────────────────────────────────────────────
  //
  // PREVIOUSLY: keyword-based text matching on ingredients_en
  //   → brittle, patchy, language-dependent
  //   → 'milk' keyword matched 'soy milk', 'oat milk', 'almond milk'
  //   → required constant patching
  //
  // NOW: structured integer array in allergens_present DB column
  //   → each product has a jsonb column: allergens_present = [1, 7, 8]
  //   → contains allergy_id for every allergen IN the product
  //     (confirmed ingredients AND may contain traces — treated equally)
  //   → filter: exclude product if any user allergy id is in allergens_present
  //   → deterministic, language-independent, zero edge cases
  //   → adding new allergens never breaks existing logic
  //
  // FLOW:
  //   1. Junction table lookup: find all candidate products for user's allergies
  //   2. Category filter: keep only products matching scanned product type
  //   3. Safety filter: exclude any candidate whose allergens_present
  //      intersects with user's allergy ids
  //   4. LLM suggestions appended as supplemental section (display only)
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

    // ── Step 1: Resolve target categories dynamically ──────────────────────
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
      // ── Step 3: Direct query — no junction table needed ──────────────────
      // Fetch all alternatives matching the target category (or all if no category).
      // Safety is determined purely by allergens_present, not junction table membership.
      // This means ANY product safe for the user's allergies will appear,
      // regardless of whether it was manually linked in a junction table.
      dynamic query = _supabase
          .from('alternatives')
          .select('id, name_ar, name_en, brand, category, image_url, allergens_present');

      if (targetCategories.isNotEmpty) {
        query = query.inFilter('category', targetCategories);
      }

      final productsResponse = await query;

      for (final row in productsResponse as List) {
        final map = row as Map<String, dynamic>;

        // ── Step 4: Safety filter via allergens_present ───────────────────
        // A product is safe if NONE of the user's allergy ids appear
        // in the product's allergens_present array.
        // This is deterministic: no keywords, no text matching, no manual upkeep.
        final List<int> productAllergenIds = _parseAllergensPresent(map['allergens_present']);

        final bool safeForUser = userAllergyIds.isEmpty ||
            !userAllergyIds.any((id) => productAllergenIds.contains(id));

        if (!safeForUser) {
          final conflicts = userAllergyIds.where((id) => productAllergenIds.contains(id)).toList();
          print('⚠️ Excluded ${map['name_en']} — allergens_present conflicts: $conflicts');
          continue;
        }

        dbProducts.add(AlternativeProduct.fromDb(map));
      }
      print('✅ DB products after safety filter: ${dbProducts.length}');
    } catch (e) {
      print('❌ DB query error: $e');
    }

    // ── Step 7: LLM suggestions — display only, no DB interaction ─────────
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
        if (!alreadyInDb) {
          llmProducts.add(AlternativeProduct.fromLlm(llmAlt));
        }
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

  /// Parses the allergens_present jsonb column value into a List<int>.
  /// Handles null, empty array, and various jsonb representations safely.
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

  static List<String> _resolveTargetCategories({
    required String productCategory,
    required String productTypeAr,
  }) {
    if (productCategory.isNotEmpty) {
      final key = productCategory.toLowerCase().trim();

      // 1. Check plain product type first (new Gemini format: "cereal", "bread", etc.)
      if (_productTypeToDbCategories.containsKey(key)) {
        final categories = _productTypeToDbCategories[key]!;
        print('🗂️ Resolved plain product type "$key" → $categories');
        return categories;
      }

      // 2. Fallback: check legacy canonical category (old Gemini format: "gluten-free cereal")
      if (_canonicalCategoryMap.containsKey(key)) {
        // Dynamically find all sibling categories sharing the same base product type.
        // e.g. "dairy-free chocolate" → base "chocolate" → also finds "nut-free chocolate"
        return _findSiblingCategories(key);
      }

      print('⚠️ Unknown category from Gemini: "$productCategory".');
      return [];
    }

    if (productTypeAr.isNotEmpty) {
      for (final entry in _arabicFallbackToCanonical.entries) {
        if (productTypeAr.contains(entry.key)) {
          return _findSiblingCategories(entry.value);
        }
      }
    }

    return [];
  }

  /// Returns all canonical categories sharing the same base product type.
  /// Strips allergen-prefixes, then matches every category with the same base noun.
  /// New categories added to _canonicalCategoryMap are automatically included.
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

  /// Strips the allergen-prefix from a category string to get the base product type.
  ///   "gluten-free cereal"  → "cereal"
  ///   "dairy-free chocolate"→ "chocolate"
  ///   "plant-based milk"    → "milk"
  ///   "nut-free snack-bar"  → "snack-bar"
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