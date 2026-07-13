import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/constants/app_constants.dart';

/// Singleton owner of the sqflite [Database] connection.
///
/// Responsibilities (and ONLY these):
///  1. Copy the preloaded seed database from assets into the app's
///     writable database directory on first launch.
///  2. Open and cache a single [Database] instance for the app's lifetime.
///  3. Own schema migrations via [onUpgrade].
///
/// Feature-specific queries belong in DAOs (see lib/data/local/daos/*),
/// never here — this class must stay small and stable.
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final String dbPath = await _resolveDatabasePath();
    final bool exists = await File(dbPath).exists();

    if (!exists) {
      await _copySeedDatabaseFromAssets(dbPath);
    }

    return openDatabase(
      dbPath,
      version: AppConstants.dbVersion,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        // Foreign keys are OFF by default in sqflite — must enable explicitly
        // for our ON DELETE CASCADE / SET NULL constraints to take effect.
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<String> _resolveDatabasePath() async {
    // Using getApplicationDocumentsDirectory (not getDatabasesPath) keeps
    // behavior identical across Android/iOS and survives app data being
    // cleared consistently with platform expectations.
    final Directory docsDir = await getApplicationDocumentsDirectory();
    final String dbDir = p.join(docsDir.path, 'databases');
    await Directory(dbDir).create(recursive: true);
    return p.join(dbDir, AppConstants.dbName);
  }

  /// Copies the bundled 50k-word seed database from the app assets
  /// bundle to [destinationPath]. This runs exactly once, on the very
  /// first app launch (detected by the destination file not existing).
  Future<void> _copySeedDatabaseFromAssets(String destinationPath) async {
    try {
      final ByteData data = await rootBundle.load(AppConstants.seedDbAssetPath);
      final List<int> bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      await File(destinationPath).writeAsBytes(bytes, flush: true);
    } catch (e) {
      // If the seed asset is missing/corrupt, fall back to an empty
      // schema so the app doesn't crash on first launch — it will simply
      // behave as an "online-only, learns as you go" dictionary until
      // fixed. This is intentional graceful degradation, not silent failure:
      // it's surfaced via DatabaseInfo in Settings (Step 22).
      await _createEmptySchema(destinationPath);
    }
  }

  /// Fallback schema creation — mirrors tools/build_seed_db.py exactly.
  /// Used only if the preloaded asset DB is missing or fails to copy.
  Future<void> _createEmptySchema(String destinationPath) async {
    final Database db = await openDatabase(destinationPath, version: AppConstants.dbVersion);
    await db.execute('''
      CREATE TABLE IF NOT EXISTS words (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        english         TEXT NOT NULL,
        bangla          TEXT NOT NULL,
        pronunciation   TEXT,
        phonetics       TEXT,
        part_of_speech  TEXT,
        example         TEXT,
        synonyms        TEXT,
        antonyms        TEXT,
        word_origin     TEXT,
        category_id     INTEGER,
        is_synced       INTEGER NOT NULL DEFAULT 0,
        last_updated    TEXT,
        search_count    INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_words_english ON words(english COLLATE NOCASE)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_words_bangla ON words(bangla)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_words_category ON words(category_id)');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        name        TEXT NOT NULL UNIQUE,
        icon_code   TEXT,
        word_count  INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS favorites (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        word_id     INTEGER NOT NULL,
        added_at    TEXT NOT NULL,
        FOREIGN KEY (word_id) REFERENCES words(id) ON DELETE CASCADE,
        UNIQUE (word_id)
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_favorites_word ON favorites(word_id)');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS search_history (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        query        TEXT NOT NULL,
        word_id      INTEGER,
        searched_at  TEXT NOT NULL,
        language     TEXT NOT NULL,
        FOREIGN KEY (word_id) REFERENCES words(id) ON DELETE SET NULL
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_history_searched_at ON search_history(searched_at DESC)');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS cached_api_data (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        word_id      INTEGER NOT NULL,
        raw_json     TEXT NOT NULL,
        source       TEXT NOT NULL DEFAULT 'dictionaryapi.dev',
        fetched_at   TEXT NOT NULL,
        FOREIGN KEY (word_id) REFERENCES words(id) ON DELETE CASCADE,
        UNIQUE (word_id)
      )
    ''');

    await db.close();
  }

  /// Schema migration entry point. Add version-gated ALTER/CREATE
  /// statements here as the schema evolves — never mutate the seed
  /// script/CREATE TABLE definitions retroactively.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Example for future use:
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE words ADD COLUMN audio_url TEXT');
    // }
  }

  /// Exposed for Settings > Database Information (Step 22) and testing.
  Future<int> getDatabaseSizeInBytes() async {
    final String dbPath = await _resolveDatabasePath();
    final File file = File(dbPath);
    if (await file.exists()) {
      return file.length();
    }
    return 0;
  }

  Future<void> close() async {
    final db = _database;
    if (db != null && db.isOpen) {
      await db.close();
      _database = null;
    }
  }
}