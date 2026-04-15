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

  // ✅ Category mapping: product_type_ar → category values in DB
  static const Map<String, List<String>> _productTypeCategories = {
    'حليب': ['dairy-drink', 'plant-based milk'],
    'مشروب حليب': ['dairy-drink', 'plant-based milk'],
    'زبادي': ['yogurt', 'plant-based yogurt'],
    'جبن': ['cheese', 'plant-based cheese'],
    'خبز': ['bread', 'gluten-free bread'],
    'شوكولاتة': ['chocolate', 'dairy-free chocolate'],
    'معكرونة': ['pasta', 'gluten-free pasta'],
    'مايونيز': ['mayonnaise', 'vegan mayo'],
    'بسكويت': ['biscuit', 'gluten-free biscuit'],
    'كيك': ['cake', 'dairy-free cake'],
  };

  static Future<List<AlternativeProduct>> getAlternatives({
    required List<String> detectedAllergenTypes,
    required List<String> llmSuggestedAlternatives,
    required List<Map<String, dynamic>> llmRawAlternatives,
    String productTypeAr = '',
  }) async {
    final List<AlternativeProduct> dbProducts = [];
    final List<AlternativeProduct> result = [];

    final List<int> allergyIds = detectedAllergenTypes
        .map((type) => _allergyIdMap[type.toLowerCase()])
        .whereType<int>()
        .toList();

    print('🔍 Allergy IDs: $allergyIds, Product type: $productTypeAr');

    // Step 1: Query DB — products safe for ALL user allergens
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

          print('🔍 Allergy $allergyId → ${ids.length} products');
          validIds = validIds == null ? ids : validIds.intersection(ids);
        }

        if (validIds != null && validIds.isNotEmpty) {
          // ✅ Filter by product category if known
          final targetCategories = _getTargetCategories(productTypeAr);

          var query = _supabase
              .from('alternatives')
              .select('id, name_ar, name_en, brand, category, image_url')
              .inFilter('id', validIds.toList());

          final productsResponse = await query;

          for (final row in productsResponse as List) {
            final product = AlternativeProduct.fromDb(row as Map<String, dynamic>);
            // ✅ If we know the product type, only show matching category
            if (targetCategories.isEmpty || targetCategories.contains(product.category)) {
              dbProducts.add(product);
            }
          }

          print('✅ DB products after category filter: ${dbProducts.length}');
        }
      } catch (e) {
        print('❌ DB query error: $e');
      }
    }

    result.addAll(dbProducts);

    // Step 2: Add LLM suggestions not already in DB
    final dbNamesLower = {
      ...dbProducts.map((p) => p.nameEn.toLowerCase()),
      ...dbProducts.map((p) => p.nameAr.toLowerCase()),
    };

    // Use rich LLM data if available
    if (llmRawAlternatives.isNotEmpty) {
      for (final llmAlt in llmRawAlternatives) {
        final name = llmAlt['name']?.toString() ?? '';
        if (name.isEmpty) continue;
        final lower = name.toLowerCase();
        final alreadyInDb = dbNamesLower.any(
          (n) => n.contains(lower) || lower.contains(n),
        );
        if (!alreadyInDb) {
          result.add(AlternativeProduct.fromLlm(llmAlt));
        }
      }
    } else {
      // Fallback: plain string list
      for (final suggestion in llmSuggestedAlternatives) {
        final lower = suggestion.toLowerCase();
        final alreadyInDb = dbNamesLower.any(
          (n) => n.contains(lower) || lower.contains(n),
        );
        if (!alreadyInDb) {
          result.add(AlternativeProduct(
            id: -1,
            nameAr: suggestion,
            nameEn: suggestion,
            brand: '',
            category: '',
            imageUrl: '',
            availableInSaudi: false,
          ));
        }
      }
    }

    print('✅ Total: ${result.length}');
    return result;
  }

  static List<String> _getTargetCategories(String productTypeAr) {
    if (productTypeAr.isEmpty) return [];
    for (final entry in _productTypeCategories.entries) {
      if (productTypeAr.contains(entry.key)) return entry.value;
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