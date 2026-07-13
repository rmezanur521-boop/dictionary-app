import '../../models/favorite_model.dart';
import '../../models/word_model.dart';
import '../database_helper.dart';

class FavoriteDao {
  FavoriteDao(this._dbHelper);
  final DatabaseHelper _dbHelper;

  Future<bool> isFavorite(int wordId) async {
    final db = await _dbHelper.database;
    final rows = await db.query('favorites', where: 'word_id = ?', whereArgs: [wordId], limit: 1);
    return rows.isNotEmpty;
  }

  Future<void> add(FavoriteModel favorite) async {
    final db = await _dbHelper.database;
    // insertOnConflict "replace" is safe here because of the UNIQUE(word_id)
    // constraint — this makes "add" idempotent without a manual exists-check.
    await db.insert(
      'favorites',
      favorite.toMap(includeId: false),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeByWordId(int wordId) async {
    final db = await _dbHelper.database;
    await db.delete('favorites', where: 'word_id = ?', whereArgs: [wordId]);
  }

  /// Returns full WordModel objects for every favorited word, joined
  /// against `words` (+ category), ordered by most-recently favorited.
  Future<List<WordModel>> getAllFavoriteWords() async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery('''
      SELECT words.*, categories.name AS category_name
      FROM favorites
      INNER JOIN words ON words.id = favorites.word_id
      LEFT JOIN categories ON categories.id = words.category_id
      ORDER BY favorites.added_at DESC
    ''');
    return rows.map(WordModel.fromMap).toList();
  }

  Future<int> getCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as c FROM favorites');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}