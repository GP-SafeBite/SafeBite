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
      version: 5,
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
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE current_user ADD COLUMN photo_url TEXT');
        }
        if (oldVersion < 4) {
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
          // Add new columns for v5
          try { await db.execute('ALTER TABLE scan_history ADD COLUMN remote_image_url TEXT'); } catch (_) {}
          try { await db.execute('ALTER TABLE scan_history ADD COLUMN alternatives_json TEXT'); } catch (_) {}
          try { await db.execute('ALTER TABLE scan_history ADD COLUMN product_name TEXT'); } catch (_) {}
          try { await db.execute('ALTER TABLE scan_history ADD COLUMN ingredients_text TEXT'); } catch (_) {}
        }
      },
    );
  }

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

  static Future<Map<String, dynamic>?> getUser() async {
    final db = await getDatabase();
    final result = await db.query('current_user', limit: 1);
    if (result.isEmpty) return null;
    return result.first;
  }

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

  static Future<List<int>> getUserAllergies({required String userId}) async {
    final db = await getDatabase();
    final result = await db.query('user_allergies', where: 'user_id = ?', whereArgs: [userId]);
    return result.map((row) => row['allergy_id'] as int).toList();
  }

  static Future<void> saveScanHistory({
    required String userId,
    required String productName,
    required String ingredientsText,
    required String foundAllergens,
    required String safetyStatus,
    String? localImagePath,
    String? remoteImageUrl,
    String? alternativesJson,
  }) async {
    final db = await getDatabase();
    await db.insert('scan_history', {
      'user_id': userId,
      'product_name': productName,
      'ingredients_text': ingredientsText,
      'found_allergens': foundAllergens,
      'safety_status': safetyStatus,
      'local_image_path': localImagePath ?? '',
      'remote_image_url': remoteImageUrl ?? '',
      'alternatives_json': alternativesJson ?? '[]',
      'scan_date': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> getScanHistory({required String userId}) async {
    final db = await getDatabase();
    return await db.query(
      'scan_history',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'scan_date DESC',
      limit: 50,
    );
  }

  static Future<void> deleteScanHistory({required String userId}) async {
    final db = await getDatabase();
    await db.delete('scan_history', where: 'user_id = ?', whereArgs: [userId]);
  }

  static Future<void> deleteSingleScan({required int historyId}) async {
    final db = await getDatabase();
    await db.delete('scan_history', where: 'history_id = ?', whereArgs: [historyId]);
  }

  static Future<void> clearUserSession() async {
    final db = await getDatabase();
    await db.delete('current_user');
    await db.delete('user_allergies');
  }
}