import '../../models/history_model.dart';
import '../../models/word_model.dart';
import '../database_helper.dart';

class HistoryDao {
  HistoryDao(this._dbHelper);
  final DatabaseHelper _dbHelper;

  Future<int> insert(HistoryModel history) async {
    final db = await _dbHelper.database;
    return db.insert('search_history', history.toMap(includeId: false));
  }

  /// Returns history joined with word data where available (word_id
  /// may be null for zero-result searches — LEFT JOIN handles that).
  Future<List<Map<String, Object?>>> getRecent({int limit = 100}) async {
    final db = await _dbHelper.database;
    return db.rawQuery('''
      SELECT search_history.*, words.english, words.bangla
      FROM search_history
      LEFT JOIN words ON words.id = search_history.word_id
      ORDER BY search_history.searched_at DESC
      LIMIT ?
    ''', [limit]);
  }

  Future<void> deleteById(int id) async {
    final db = await _dbHelper.database;
    await db.delete('search_history', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAll() async {
    final db = await _dbHelper.database;
    await db.delete('search_history');
  }
}