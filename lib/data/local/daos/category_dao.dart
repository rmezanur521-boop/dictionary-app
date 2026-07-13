import '../../models/category_model.dart';
import '../database_helper.dart';

class CategoryDao {
  CategoryDao(this._dbHelper);
  final DatabaseHelper _dbHelper;

  Future<List<CategoryModel>> getAll() async {
    final db = await _dbHelper.database;
    final rows = await db.query('categories', orderBy: 'name ASC');
    return rows.map(CategoryModel.fromMap).toList();
  }

  Future<CategoryModel?> getById(int id) async {
    final db = await _dbHelper.database;
    final rows = await db.query('categories', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return CategoryModel.fromMap(rows.first);
  }
}