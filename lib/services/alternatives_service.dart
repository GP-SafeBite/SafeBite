import 'package:supabase_flutter/supabase_flutter.dart';

class AlternativeProduct {
  final int id;
  final String nameAr;
  final String nameEn;
  final String brand;
  final String category;
  final String imageUrl;
  final String ingredientsEn;
  final String ingredientsAr;
  final bool availableInSaudi;

  AlternativeProduct({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.brand,
    required this.category,
    required this.imageUrl,
    required this.ingredientsEn,
    required this.ingredientsAr,
    required this.availableInSaudi,
  });

  factory AlternativeProduct.fromDb(Map<String, dynamic> json) {
    return AlternativeProduct(
      id: (json['id'] as num).toInt(),
      nameAr: json['name_ar']?.toString() ?? '',
      nameEn: json['name_en']?.toString() ?? '',
      brand: json['brand']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      imageUrl: json['image_url']?.toString() ?? '',
      ingredientsEn: json['ingredients_en']?.toString() ?? '',
      ingredientsAr: json['ingredients_ar']?.toString() ?? '',
      availableInSaudi: true,
    );
  }

  factory AlternativeProduct.fromLlm(String name) {
    return AlternativeProduct(
      id: -1,
      nameAr: name,
      nameEn: name,
      brand: '',
      category: '',
      imageUrl: '',
      ingredientsEn: '',
      ingredientsAr: '',
      availableInSaudi: false,
    );
  }
}

class AlternativesService {
  static final _supabase = Supabase.instance.client;

  static const Map<String, int> _allergyIdMap = {
    'milk': 1, 'eggs': 2, 'gluten': 3, 'crustaceans': 4,
    'fish': 5, 'peanuts': 6, 'soybeans': 7, 'treenuts': 8,
    'celery': 9, 'mustard': 10, 'sesame': 11, 'sulfur': 12,
    'lupin': 13, 'mollusks': 14,
  };

  static Future<List<AlternativeProduct>> getAlternatives({
    required List<String> detectedAllergenTypes,
    required List<String> llmSuggestedAlternatives,
  }) async {
    final List<AlternativeProduct> dbProducts = [];
    final List<AlternativeProduct> result = [];

    final List<int> allergyIds = detectedAllergenTypes
        .map((type) => _allergyIdMap[type.toLowerCase()])
        .whereType<int>()
        .toList();

    print('🔍 Allergy IDs to query: $allergyIds');

    // ✅ FIXED DB QUERY: Two-step approach
    // Step 1: For each allergy, get safe alternative IDs
    // Step 2: Intersect → product must be safe for ALL allergies
    // Step 3: Fetch product details
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

          print('🔍 Allergy ID $allergyId → ${ids.length} products: $ids');

          if (validIds == null) {
            validIds = ids;
          } else {
            validIds = validIds.intersection(ids);
          }
        }

        print('🔍 After intersection: ${validIds?.length ?? 0} products → $validIds');

        if (validIds != null && validIds.isNotEmpty) {
          final productsResponse = await _supabase
              .from('alternatives')
              .select('id, name_ar, name_en, brand, category, image_url, ingredients_en, ingredients_ar')
              .inFilter('id', validIds.toList());

          print('📦 Products fetched: ${(productsResponse as List).length}');

          for (final row in productsResponse) {
            dbProducts.add(AlternativeProduct.fromDb(row as Map<String, dynamic>));
          }
        }
      } catch (e) {
        print('❌ DB query error: $e');
      }
    }

    print('✅ DB products: ${dbProducts.length}');

    // Add DB products first
    result.addAll(dbProducts);

    // Add LLM suggestions not already in DB
    final dbNamesLower = {
      ...dbProducts.map((p) => p.nameEn.toLowerCase()),
      ...dbProducts.map((p) => p.nameAr.toLowerCase()),
    };

    for (final llmSuggestion in llmSuggestedAlternatives) {
      final lower = llmSuggestion.toLowerCase();
      final alreadyInDb = dbNamesLower.any(
        (name) => name.contains(lower) || lower.contains(name),
      );
      if (!alreadyInDb) {
        result.add(AlternativeProduct.fromLlm(llmSuggestion));
      }
    }

    print('✅ Total: ${result.length} (${dbProducts.length} Saudi + ${result.length - dbProducts.length} LLM)');
    return result;
  }
}