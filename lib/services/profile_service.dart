// Profile Service - Manage user allergen selections with synchronization between Supabase and SQLite

import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/local_db.dart';

class ProfileResult {
  final bool success;
  final String message;
  final dynamic data;

  ProfileResult({
    required this.success,
    required this.message,
    this.data,
  });
}

class ProfileService {
  static final _supabase = Supabase.instance.client;

  // Maps frontend string allergen identifiers to Supabase allergy_id integers
  static const Map<String, int> _allergyIdMap = {
    'milk': 1,
    'eggs': 2,
    'gluten': 3,
    'crustaceans': 4,
    'fish': 5,
    'peanuts': 6,
    'soybeans': 7,
    'treenuts': 8,
    'celery': 9,
    'mustard': 10,
    'sesame': 11,
    'sulfur': 12,
    'lupin': 13,
    'mollusks': 14,
  };

  // Maps Supabase allergy_id integers back to frontend string allergen identifiers
  static const Map<int, String> allergyReverseMap = {
    1: 'milk',
    2: 'eggs',
    3: 'gluten',
    4: 'crustaceans',
    5: 'fish',
    6: 'peanuts',
    7: 'soybeans',
    8: 'treenuts',
    9: 'celery',
    10: 'mustard',
    11: 'sesame',
    12: 'sulfur',
    13: 'lupin',
    14: 'mollusks',
  };

  // ── Allergen Management Methods ──────────────────────────────────────────

  // Save initial allergen selections to Supabase and SQLite during first-time profile setup
  static Future<ProfileResult> saveUserAllergens({
    required String userId,
    required Set<String> selectedIds,
  }) async {
    try {
      final List<int> allergyIds = selectedIds
          .where((id) => _allergyIdMap.containsKey(id))
          .map((id) => _allergyIdMap[id]!)
          .toList();

      // Delete existing selections before inserting to ensure a clean state
      await _supabase
          .from('userallergy')
          .delete()
          .eq('user_id', userId);

      if (allergyIds.isNotEmpty) {
        final rows = allergyIds
            .map((id) => {'user_id': userId, 'allergy_id': id})
            .toList();

        await _supabase.from('userallergy').insert(rows);
      }

      await LocalDB.saveUserAllergies(
        userId: userId,
        allergyIds: allergyIds,
      );

      return ProfileResult(
        success: true,
        message: 'تم حفظ الحساسيات بنجاح',
        data: allergyIds,
      );

    } catch (e) {
      print('❌ Save allergens error: $e');
      return ProfileResult(
        success: false,
        message: 'فشل حفظ الحساسيات. تحقق من الاتصال',
      );
    }
  }

  // Retrieve user allergen selections as a Set of string IDs.
  // Reads from SQLite first for offline support, falling back to Supabase if local data is empty.
  static Future<ProfileResult> getUserAllergens({
    required String userId,
  }) async {
    try {
      final localIds = await LocalDB.getUserAllergies(userId: userId);

      if (localIds.isNotEmpty) {
        final stringIds = localIds
            .map((id) => allergyReverseMap[id])
            .whereType<String>()
            .cast<String>()
            .toSet();

        return ProfileResult(
          success: true,
          message: 'تم تحميل الحساسيات',
          data: stringIds,
        );
      }

      // Local cache is empty — fetch from Supabase and store locally for subsequent requests
      final response = await _supabase
          .from('userallergy')
          .select('allergy_id')
          .eq('user_id', userId);

      final List<int> supabaseIds = (response as List)
          .map((row) => row['allergy_id'] as int)
          .toList();

      await LocalDB.saveUserAllergies(
        userId: userId,
        allergyIds: supabaseIds,
      );

      final stringIds = supabaseIds
          .map((id) => allergyReverseMap[id])
          .whereType<String>()
          .cast<String>()
          .toSet();

      return ProfileResult(
        success: true,
        message: 'تم تحميل الحساسيات',
        data: stringIds,
      );

    } catch (e) {
      return ProfileResult(
        success: false,
        message: 'فشل تحميل الحساسيات',
        data: <String>{},
      );
    }
  }

  // Replace existing allergen selections with the updated set from the edit allergies screen
  static Future<ProfileResult> updateUserAllergens({
    required String userId,
    required Set<String> selectedIds,
  }) async {
    return await saveUserAllergens(
      userId: userId,
      selectedIds: selectedIds,
    );
  }
}