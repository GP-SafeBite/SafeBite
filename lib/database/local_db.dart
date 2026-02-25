import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDB {
  static Database? _database;

  static Future<Database> getDatabase() async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'safebite_local.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {

        // Mirrors your Supabase User table (no password — Supabase handles that)
        await db.execute('''
          CREATE TABLE current_user (
            user_id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            email TEXT NOT NULL,
            created_at TEXT
          )
        ''');

        // Mirrors your Supabase Allergy table (name_ar added)
        await db.execute('''
          CREATE TABLE cached_allergies (
            allergy_id INTEGER PRIMARY KEY,
            name_en TEXT NOT NULL,
            name_ar TEXT NOT NULL
          )
        ''');

        // Mirrors your Supabase UserAllergy table
        await db.execute('''
          CREATE TABLE user_allergies (
            user_id TEXT NOT NULL,
            allergy_id INTEGER NOT NULL,
            PRIMARY KEY (user_id, allergy_id)
          )
        ''');

        // Mirrors your Supabase ScanHistory table (with new columns)
        await db.execute('''
          CREATE TABLE scan_history (
            history_id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT NOT NULL,
            product_id TEXT NOT NULL,
            product_name TEXT,
            product_image_url TEXT,
            found_allergens TEXT,
            safety_status TEXT NOT NULL,
            scan_date TEXT NOT NULL
          )
        ''');
      },
    );
  }

  // ── User operations ──────────────────────────

  static Future<void> saveUser({
    required String userId,
    required String email,
    required String name,
  }) async {
    final db = await getDatabase();
    await db.delete('current_user'); // only one user at a time
    await db.insert('current_user', {
      'user_id': userId,
      'email': email,
      'name': name,
      'created_at': DateTime.now().toIso8601String(),
    });
    
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final db = await getDatabase();
    final result = await db.query('current_user', limit: 1);
    if (result.isEmpty) return null;
    return result.first;
  }

  static Future<void> clearUser() async {
    final db = await getDatabase();
    await db.delete('current_user');
    // Also clear personal cached data on logout
    await db.delete('user_allergies');
    await db.delete('scan_history');
  }

  // ── Allergy operations ────────────────────────

// 🔴 NEW: Save user's allergy selections to SQLite
static Future<void> saveUserAllergies({
  required String userId,
  required List<int> allergyIds,
}) async {
  final db = await getDatabase();

  // Delete old selections for this user
  await db.delete(
    'user_allergies',
    where: 'user_id = ?',
    whereArgs: [userId],
  );

  // Insert new selections
  for (final allergyId in allergyIds) {
    await db.insert('user_allergies', {
      'user_id': userId,
      'allergy_id': allergyId,
    });
  }
}

// 🔴 NEW: Get user's allergy selections from SQLite
static Future<List<int>> getUserAllergies({
  required String userId,
}) async {
  final db = await getDatabase();
  final result = await db.query(
    'user_allergies',
    where: 'user_id = ?',
    whereArgs: [userId],
  );

  return result.map((row) => row['allergy_id'] as int).toList();
}

// ── Scan History operations ───────────────────

// 🔴 NEW: Save scan to local SQLite history
static Future<void> saveScanHistory({
  required String userId,
  required String productId,
  required String productName,
  required String productImageUrl,
  required String foundAllergens,
  required String safetyStatus,
}) async {
  final db = await getDatabase();
  await db.insert('scan_history', {
    'user_id': userId,
    'product_id': productId,
    'product_name': productName,
    'product_image_url': productImageUrl,
    'found_allergens': foundAllergens,
    'safety_status': safetyStatus,
    'scan_date': DateTime.now().toIso8601String(),
  });
}

// 🔴 NEW: Get scan history from SQLite
static Future<List<Map<String, dynamic>>> getScanHistory({
  required String userId,
}) async {
  final db = await getDatabase();
  return await db.query(
    'scan_history',
    where: 'user_id = ?',
    whereArgs: [userId],
    orderBy: 'scan_date DESC',
    limit: 50,
  );
}

/// Clear ONLY user session data (keeps scan history)
static Future<void> clearUserSession() async {
  final db = await getDatabase();
  
  // Clear user data
  await db.delete('current_user');
  
  // Clear user's allergy selections
  await db.delete('user_allergies');
  
  // ✅ DO NOT delete 'scan_history' — we want to keep it!
}
}