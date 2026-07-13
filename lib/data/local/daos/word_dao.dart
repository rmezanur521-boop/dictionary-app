import 'package:sqflite/sqflite.dart';

import '../../models/word_model.dart';
import '../database_helper.dart';

/// All raw SQL for the `words` table lives here — nowhere else in the
/// app should construct a query against this table directly.
class WordDao {
  WordDao(this._dbHelper);
  final DatabaseHelper _dbHelper;

  static const String _table = 'words';

  /// Base SELECT with category name joined in — used by every read
  /// method so callers get `categoryName` populated for free.
  static const String _selectWithCategory = '''
    SELECT words.*, categories.name AS category_name
    FROM words
    LEFT JOIN categories ON categories.id = words.category_id
  ''';

  Future<WordModel?> getById(int id) async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery('$_selectWithCategory WHERE words.id = ?', [id]);
    if (rows.isEmpty) return null;
    return WordModel.fromMap(rows.first);
  }

  /// Exact match lookup — used to check "does this exact word already
  /// exist locally" before deciding to hit the API (Step 16).
  Future<WordModel?> getByExactEnglish(String english) async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery(
      '$_selectWithCategory WHERE words.english = ? COLLATE NOCASE LIMIT 1',
      [english.trim()],
    );
    if (rows.isEmpty) return null;
    return WordModel.fromMap(rows.first);
  }

  Future<WordModel?> getByExactBangla(String bangla) async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery(
      '$_selectWithCategory WHERE words.bangla = ? LIMIT 1',
      [bangla.trim()],
    );
    if (rows.isEmpty) return null;
    return WordModel.fromMap(rows.first);
  }

  /// Prefix + substring search across BOTH english and bangla columns,
  /// used for instant search suggestions. Prefix matches (english LIKE
  /// 'query%') are ranked first since they hit the index; substring
  /// matches ('%query%') are appended after for recall.
  Future<List<WordModel>> search({
    required String query,
    int limit = 30,
  }) async {
    final db = await _dbHelper.database;
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    final rows = await db.rawQuery('''
      $_selectWithCategory
      WHERE words.english LIKE ? COLLATE NOCASE
         OR words.bangla LIKE ?
      ORDER BY
        CASE
          WHEN words.english LIKE ? COLLATE NOCASE THEN 0
          WHEN words.bangla LIKE ? THEN 0
          ELSE 1
        END,
        LENGTH(words.english) ASC
      LIMIT ?
    ''', [
      '%$trimmed%', '%$trimmed%',
      '$trimmed%', '$trimmed%',
      limit,
    ]);

    return rows.map(WordModel.fromMap).toList();
  }

  Future<List<WordModel>> getByCategory(int categoryId, {int limit = 200, int offset = 0}) async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery(
      '$_selectWithCategory WHERE words.category_id = ? ORDER BY words.english ASC LIMIT ? OFFSET ?',
      [categoryId, limit, offset],
    );
    return rows.map(WordModel.fromMap).toList();
  }

  Future<List<WordModel>> getMostSearched({int limit = 10}) async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery(
      '$_selectWithCategory WHERE words.search_count > 0 ORDER BY words.search_count DESC LIMIT ?',
      [limit],
    );
    return rows.map(WordModel.fromMap).toList();
  }

  /// Deterministic random-by-id word for Daily Word (Step 20 seeds the
  /// actual date-based selection; this DAO just fetches by id or a
  /// pseudo-random offset).
  Future<WordModel?> getRandomWord({required int seed}) async {
    final db = await _dbHelper.database;
    final countResult = await db.rawQuery('SELECT COUNT(*) as c FROM words');
    final total = Sqflite.firstIntValue(countResult) ?? 0;
    if (total == 0) return null;

    final offset = seed % total;
    final rows = await db.rawQuery(
      '$_selectWithCategory ORDER BY words.id LIMIT 1 OFFSET ?',
      [offset],
    );
    if (rows.isEmpty) return null;
    return WordModel.fromMap(rows.first);
  }

  Future<int> insert(WordModel word) async {
    final db = await _dbHelper.database;
    return db.insert(_table, word.toMap(includeId: false));
  }

  Future<int> update(WordModel word) async {
    final db = await _dbHelper.database;
    return db.update(_table, word.toMap(includeId: false), where: 'id = ?', whereArgs: [word.id]);
  }

  /// Used by the sync layer (Step 16) after merging API enrichment —
  /// a focused update that touches only enrichment columns, so we
  /// never accidentally clobber english/bangla/category via a stale
  /// in-memory object.
  Future<int> updateEnrichment(WordModel word) async {
    final db = await _dbHelper.database;
    return db.update(
      _table,
      {
        'pronunciation': word.pronunciation,
        'phonetics': word.phonetics,
        'part_of_speech': word.partOfSpeech,
        'example': word.example,
        'synonyms': word.toMap()['synonyms'],
        'antonyms': word.toMap()['antonyms'],
        'word_origin': word.wordOrigin,
        'is_synced': 1,
        'last_updated': word.lastUpdated?.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [word.id],
    );
  }

  Future<void> incrementSearchCount(int wordId) async {
    final db = await _dbHelper.database;
    await db.rawUpdate(
      'UPDATE $_table SET search_count = search_count + 1 WHERE id = ?',
      [wordId],
    );
  }

  Future<int> getTotalWordCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as c FROM $_table');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getSyncedWordCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as c FROM $_table WHERE is_synced = 1');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}