// Local Database - Manage SQLite persistence for user session, allergies, and scan history

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDB {
  static Database? _database;

  // Return the existing database instance or initialize it if not yet open
  static Future<Database> getDatabase() async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize SQLite database and apply schema creation and migrations
  static Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'safebite_local.db');
    return await openDatabase(
      path,
      version: 7,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE current_user (
            user_id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            email TEXT NOT NULL,
            photo_url TEXT,
            created_at TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE cached_allergies (
            allergy_id INTEGER PRIMARY KEY,
            name_en TEXT NOT NULL,
            name_ar TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE user_allergies (
            user_id TEXT NOT NULL,
            allergy_id INTEGER NOT NULL,
            PRIMARY KEY (user_id, allergy_id)
          )
        ''');
        await db.execute('''
          CREATE TABLE scan_history (
            history_id INTEGER PRIMARY KEY AUTOINCREMENT,
            supabase_id TEXT,
            user_id TEXT NOT NULL,
            product_name TEXT,
            ingredients_text TEXT,
            found_allergens TEXT,
            alternatives_json TEXT,
            safety_status TEXT NOT NULL,
            local_image_path TEXT,
            remote_image_url TEXT,
            scan_date TEXT NOT NULL
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_scan_history_user_id ON scan_history(user_id)',
        );
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE current_user ADD COLUMN photo_url TEXT');
        }
        if (oldVersion < 4) {
          // Rebuild scan_history with extended schema — previous version lacked several columns
          await db.execute('DROP TABLE IF EXISTS scan_history');
          await db.execute('''
            CREATE TABLE scan_history (
              history_id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id TEXT NOT NULL,
              product_name TEXT,
              ingredients_text TEXT,
              found_allergens TEXT,
              safety_status TEXT NOT NULL,
              local_image_path TEXT,
              scan_date TEXT NOT NULL
            )
          ''');
        }
        if (oldVersion < 5) {
          try { await db.execute('ALTER TABLE scan_history ADD COLUMN remote_image_url TEXT'); } catch (_) {}
          try { await db.execute('ALTER TABLE scan_history ADD COLUMN alternatives_json TEXT'); } catch (_) {}
        }
        if (oldVersion < 6) {
          try { await db.execute('ALTER TABLE scan_history ADD COLUMN supabase_id TEXT'); } catch (_) {}
        }
        if (oldVersion < 7) {
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_scan_history_user_id ON scan_history(user_id)',
          );
        }
      },
    );
  }

  // ── User Operations ──────────────────────────────────────────────────────

  // Persist authenticated user data, replacing any existing record
  static Future<void> saveUser({
    required String userId,
    required String email,
    required String name,
    String? photoUrl,
  }) async {
    final db = await getDatabase();
    await db.delete('current_user');
    await db.insert('current_user', {
      'user_id': userId,
      'email': email,
      'name': name,
      'photo_url': photoUrl ?? '',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // Retrieve the currently saved user record
  static Future<Map<String, dynamic>?> getUser() async {
    final db = await getDatabase();
    final result = await db.query('current_user', limit: 1);
    if (result.isEmpty) return null;
    return result.first;
  }

  // Update the stored profile photo URL for a given user
  static Future<void> updateUserPhoto({
    required String userId,
    required String photoUrl,
  }) async {
    final db = await getDatabase();
    await db.update(
      'current_user',
      {'photo_url': photoUrl},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  // ── Allergy Operations ───────────────────────────────────────────────────

  // Replace all saved allergy selections for a user with the provided list
  static Future<void> saveUserAllergies({
    required String userId,
    required List<int> allergyIds,
  }) async {
    final db = await getDatabase();
    await db.delete('user_allergies', where: 'user_id = ?', whereArgs: [userId]);
    for (final allergyId in allergyIds) {
      await db.insert('user_allergies', {'user_id': userId, 'allergy_id': allergyId});
    }
  }

  // Retrieve all saved allergy IDs for a user
  static Future<List<int>> getUserAllergies({required String userId}) async {
    final db = await getDatabase();
    final result = await db.query('user_allergies', where: 'user_id = ?', whereArgs: [userId]);
    return result.map((row) => row['allergy_id'] as int).toList();
  }

  // ── Scan History Operations ──────────────────────────────────────────────

  // Save a scan record to local history using the timestamp provided by the caller
  // to ensure SQLite and Supabase store an identical scan_date value
  static Future<void> saveScanHistory({
    required String userId,
    required String productName,
    required String ingredientsText,
    required String foundAllergens,
    required String safetyStatus,
    String? localImagePath,
    String? remoteImageUrl,
    String? alternativesJson,
    String? supabaseId,
    String? scanDate,
  }) async {
    final db = await getDatabase();
    await db.insert('scan_history', {
      'supabase_id': supabaseId ?? '',
      'user_id': userId,
      'product_name': productName,
      'ingredients_text': ingredientsText,
      'found_allergens': foundAllergens,
      'safety_status': safetyStatus,
      'local_image_path': localImagePath ?? '',
      'remote_image_url': remoteImageUrl ?? '',
      'alternatives_json': alternativesJson ?? '[]',
      // Use caller-provided date to keep timestamps consistent across both databases
      'scan_date': scanDate ?? DateTime.now().toIso8601String(),
    });
  }

  // Retrieve scan history records for a user ordered by most recent first
  static Future<List<Map<String, dynamic>>> getScanHistory({required String userId}) async {
    final db = await getDatabase();
    return await db.query(
      'scan_history',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'scan_date DESC',
      limit: 500,
    );
  }

  // Delete all scan history records for a user
  static Future<void> deleteScanHistory({required String userId}) async {
    final db = await getDatabase();
    await db.delete('scan_history', where: 'user_id = ?', whereArgs: [userId]);
  }

  // Delete a single scan by Supabase ID, falling back to scan_date if no match is found
  static Future<void> deleteSingleScan({
    required int supabaseHistoryId,
    String? scanDate,
  }) async {
    final db = await getDatabase();
    final idStr = supabaseHistoryId.toString();
    final affected = await db.delete(
      'scan_history',
      where: 'supabase_id = ?',
      whereArgs: [idStr],
    );
    if (affected == 0 && scanDate != null && scanDate.isNotEmpty) {
      await db.delete(
        'scan_history',
        where: 'scan_date = ?',
        whereArgs: [scanDate],
      );
    }
  }

  // Clear user session data including profile and allergy selections
  static Future<void> clearUserSession() async {
    final db = await getDatabase();
    await db.delete('current_user');
    await db.delete('user_allergies');
  }
}