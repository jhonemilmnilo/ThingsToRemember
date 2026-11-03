import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class LocalVaultDb {
  LocalVaultDb._();
  static final LocalVaultDb instance = LocalVaultDb._();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'passkeep_local_vault.db');

    return await openDatabase(
      path,
      version: 2,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Add missing 'notes' column if upgrading
          try {
            await db.execute('ALTER TABLE local_credentials ADD COLUMN notes TEXT');
          } catch (_) {}
        }
      },
      onCreate: (db, version) async {
        // 1. Passwords / Accounts
        await db.execute('''
          CREATE TABLE local_credentials (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            title TEXT NOT NULL,
            category TEXT,
            username_or_email TEXT NOT NULL,
            encrypted_password TEXT NOT NULL,
            iv TEXT,
            website_url TEXT,
            notes TEXT,
            is_pinned INTEGER DEFAULT 0,
            is_synced INTEGER DEFAULT 0,
            is_deleted INTEGER DEFAULT 0,
            created_at TEXT,
            updated_at TEXT
          )
        ''');

        // 2. Secrets / Secure Notes
        await db.execute('''
          CREATE TABLE local_secure_notes (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            is_pinned INTEGER DEFAULT 0,
            is_synced INTEGER DEFAULT 0,
            is_deleted INTEGER DEFAULT 0,
            created_at TEXT,
            updated_at TEXT
          )
        ''');

        // 3. Emergency Contacts
        await db.execute('''
          CREATE TABLE local_emergency_contacts (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            name TEXT NOT NULL,
            phone_number TEXT NOT NULL,
            relationship TEXT,
            notes TEXT,
            is_pinned INTEGER DEFAULT 0,
            is_synced INTEGER DEFAULT 0,
            is_deleted INTEGER DEFAULT 0,
            created_at TEXT,
            updated_at TEXT
          )
        ''');

        // 4. Family Members / Birthdays
        await db.execute('''
          CREATE TABLE local_family_members (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            name TEXT NOT NULL,
            relationship TEXT,
            birthdate TEXT NOT NULL,
            notes TEXT,
            is_pinned INTEGER DEFAULT 0,
            is_synced INTEGER DEFAULT 0,
            is_deleted INTEGER DEFAULT 0,
            created_at TEXT,
            updated_at TEXT
          )
        ''');

        // 5. WiFi Networks
        await db.execute('''
          CREATE TABLE local_wifi_networks (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            ssid TEXT NOT NULL,
            password TEXT NOT NULL,
            security_type TEXT,
            notes TEXT,
            is_pinned INTEGER DEFAULT 0,
            is_synced INTEGER DEFAULT 0,
            is_deleted INTEGER DEFAULT 0,
            created_at TEXT,
            updated_at TEXT
          )
        ''');
      },
    );
  }

  // ==========================================
  // 📥 READ ALL ACTIVE ITEMS FOR USER
  // ==========================================
  Future<Map<String, List<Map<String, dynamic>>>> getAllVaultItems(String userId) async {
    final db = await database;

    final credentials = await db.query(
      'local_credentials',
      where: 'user_id = ? AND is_deleted = 0',
      whereArgs: [userId],
      orderBy: 'is_pinned DESC, is_synced ASC, updated_at DESC, created_at DESC',
    );

    final secrets = await db.query(
      'local_secure_notes',
      where: 'user_id = ? AND is_deleted = 0',
      whereArgs: [userId],
      orderBy: 'is_pinned DESC, is_synced ASC, updated_at DESC, created_at DESC',
    );

    final contacts = await db.query(
      'local_emergency_contacts',
      where: 'user_id = ? AND is_deleted = 0',
      whereArgs: [userId],
      orderBy: 'is_pinned DESC, is_synced ASC, updated_at DESC, created_at DESC',
    );

    final birthdays = await db.query(
      'local_family_members',
      where: 'user_id = ? AND is_deleted = 0',
      whereArgs: [userId],
      orderBy: 'is_pinned DESC, is_synced ASC, updated_at DESC, created_at DESC',
    );

    final wifi = await db.query(
      'local_wifi_networks',
      where: 'user_id = ? AND is_deleted = 0',
      whereArgs: [userId],
      orderBy: 'is_pinned DESC, is_synced ASC, updated_at DESC, created_at DESC',
    );

    return {
      'passwords': credentials,
      'secrets': secrets,
      'contacts': contacts,
      'birthdays': birthdays,
      'wifi': wifi,
    };
  }

  // ==========================================
  // ✍️ UPSERT ITEM (Insert or Update with Dirty Flag)
  // ==========================================
  Future<void> upsertLocalItem({
    required String table,
    required Map<String, dynamic> row,
    bool markDirty = true,
  }) async {
    final db = await database;
    final data = Map<String, dynamic>.from(row);

    if (markDirty) {
      data['is_synced'] = 0; // 👈 Forces dirty flag so it will push to cloud
      data['updated_at'] = DateTime.now().toIso8601String();
    } else {
      data['is_synced'] = 1; // Pulled fresh from Neon
    }

    // Default is_deleted to 0 if not provided
    data['is_deleted'] = data['is_deleted'] ?? 0;

    await db.insert(
      table,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ==========================================
  // 🗑️ HARD DELETE ITEM (Permanently remove row immediately)
  // ==========================================
  Future<void> hardDeleteItem({
    required String table,
    required String id,
  }) async {
    final db = await database;
    await db.delete(
      table,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==========================================
  // 🗑️ SOFT DELETE ITEM (Queues for cloud sync)
  // ==========================================
  Future<void> softDeleteItem({
    required String table,
    required String id,
  }) async {
    final db = await database;
    await db.update(
      table,
      {
        'is_deleted': 1,
        'is_synced': 0, // 👈 Mark dirty to notify cloud to delete
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==========================================
  // 🔍 CHECK UNSYNCED COUNT (For UI Badging)
  // ==========================================
  Future<int> getUnsyncedCount(String userId) async {
    final db = await database;
    int total = 0;
    const tables = [
      'local_credentials',
      'local_secure_notes',
      'local_emergency_contacts',
      'local_family_members',
      'local_wifi_networks',
    ];

    for (final table in tables) {
      final res = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $table WHERE user_id = ? AND is_synced = 0',
        [userId],
      );
      if (res.isNotEmpty) {
        total += (res.first['count'] as int?) ?? 0;
      }
    }
    return total;
  }

  // ==========================================
  // 🚀 GET ALL UNSYNCED MUTATIONS (For Push Phase)
  // ==========================================
  Future<Map<String, List<Map<String, dynamic>>>> getUnsyncedItems(String userId) async {
    final db = await database;

    final creds = await db.query('local_credentials', where: 'user_id = ? AND is_synced = 0', whereArgs: [userId]);
    final notes = await db.query('local_secure_notes', where: 'user_id = ? AND is_synced = 0', whereArgs: [userId]);
    final contacts = await db.query('local_emergency_contacts', where: 'user_id = ? AND is_synced = 0', whereArgs: [userId]);
    final bdays = await db.query('local_family_members', where: 'user_id = ? AND is_synced = 0', whereArgs: [userId]);
    final wifi = await db.query('local_wifi_networks', where: 'user_id = ? AND is_synced = 0', whereArgs: [userId]);

    return {
      'credentials': creds,
      'secure_notes': notes,
      'emergency_contacts': contacts,
      'family_members': bdays,
      'wifi_networks': wifi,
    };
  }

  // ==========================================
  // ✅ MARK BATCH AS SYNCED / PURGE SOFT-DELETED
  // ==========================================
  Future<void> markBatchSynced({
    required String table,
    required List<String> activeIds,
    required List<String> deletedIds,
  }) async {
    final db = await database;
    final batch = db.batch();

    // Mark active items as synced
    for (final id in activeIds) {
      batch.update(
        table,
        {'is_synced': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    }

    // Permanently remove soft-deleted items after server confirmed delete
    for (final id in deletedIds) {
      batch.delete(
        table,
        where: 'id = ?',
        whereArgs: [id],
      );
    }

    await batch.commit(noResult: true);
  }

  // ==========================================
  // 🧹 WIPE LOCAL DATABASE ON LOGOUT
  // ==========================================
  Future<void> clearAllLocalData() async {
    final db = await database;
    await db.delete('local_credentials');
    await db.delete('local_secure_notes');
    await db.delete('local_emergency_contacts');
    await db.delete('local_family_members');
    await db.delete('local_wifi_networks');
  }
}

