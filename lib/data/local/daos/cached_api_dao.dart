import 'package:sqflite/sqflite.dart';

import '../../models/cached_api_model.dart';
import '../database_helper.dart';

class CachedApiDao {
  CachedApiDao(this._dbHelper);
  final DatabaseHelper _dbHelper;

  Future<bool> hasCachedResponse(int wordId) async {
    final db = await _dbHelper.database;
    final rows = await db.query('cached_api_data', where: 'word_id = ?', whereArgs: [wordId], limit: 1);
    return rows.isNotEmpty;
  }

  Future<void> save(CachedApiModel cached) async {
    final db = await _dbHelper.database;
    await db.insert(
      'cached_api_data',
      cached.toMap(includeId: false),
      // Schema-level duplicate prevention (Step 4 rationale) — a
      // second fetch for the same word_id replaces, never duplicates.
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}