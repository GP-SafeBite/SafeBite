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

  // Maps frontend string id → Supabase allergy_id number
  // Must match exactly what's in your Supabase Allergy table
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

  // Reverse map → Supabase allergy_id number → frontend string id
  static const Map<int, String> allergyReverseMap = { // 🔴 removed underscore to make public
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

  // ──────────────────────────────────────────────
  // SAVE USER ALLERGENS (first time setup)
  // Called from ProfileSetupScreen after signup
  // Saves to both Supabase and SQLite
  // ──────────────────────────────────────────────
  static Future<ProfileResult> saveUserAllergens({
    required String userId,
    required Set<String> selectedIds,
  }) async {
    try {
      // Convert string ids to integer allergy_ids
      final List<int> allergyIds = selectedIds
          .where((id) => _allergyIdMap.containsKey(id))
          .map((id) => _allergyIdMap[id]!)
          .toList();

      // Save to Supabase UserAllergy table
      // First delete any existing selections (clean save)
      await _supabase
          .from('userallergy')
          .delete()
          .eq('user_id', userId);

      // Insert new selections
      if (allergyIds.isNotEmpty) {
        final rows = allergyIds
            .map((id) => {'user_id': userId, 'allergy_id': id})
            .toList();

        await _supabase.from('userallergy').insert(rows);
      }

      // Save to SQLite
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

  // ──────────────────────────────────────────────
  // GET USER ALLERGENS
  // Returns Set<String> of frontend ids like {'milk', 'eggs'}
  // Tries SQLite first (fast/offline), falls back to Supabase
  // ──────────────────────────────────────────────
  static Future<ProfileResult> getUserAllergens({
    required String userId,
  }) async {
    try {
      // Try SQLite first
      final localIds = await LocalDB.getUserAllergies(userId: userId);

      if (localIds.isNotEmpty) {
        // Convert int ids back to string ids
        final stringIds = localIds
            .map((id) => allergyReverseMap[id])
            .where((id) => id != null)
            .cast<String>()
            .toSet();

        return ProfileResult(
          success: true,
          message: 'تم تحميل الحساسيات',
          data: stringIds,
        );
      }

      // SQLite empty → fetch from Supabase
      final response = await _supabase
          .from('userallergy')
          .select('allergy_id')
          .eq('user_id', userId);

      final List<int> supabaseIds = (response as List)
          .map((row) => row['allergy_id'] as int)
          .toList();

      // Cache in SQLite for next time
      await LocalDB.saveUserAllergies(
        userId: userId,
        allergyIds: supabaseIds,
      );

      // Convert to string ids
      final stringIds = supabaseIds
          .map((id) => allergyReverseMap[id])
          .where((id) => id != null)
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

  // ──────────────────────────────────────────────
  // UPDATE USER ALLERGENS
  // Called from EditAllergiesScreen
  // Replaces old selections with new ones
  // ──────────────────────────────────────────────
  static Future<ProfileResult> updateUserAllergens({
    required String userId,
    required Set<String> selectedIds,
  }) async {
    // Same as save — it deletes old and inserts new
    return await saveUserAllergens(
      userId: userId,
      selectedIds: selectedIds,
    );
  }
}