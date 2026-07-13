import '../entities/category_entity.dart';
import '../entities/word_entity.dart';

abstract class CategoryRepository {
  Future<List<CategoryEntity>> getAllCategories();
  Future<List<WordEntity>> getWordsInCategory(int categoryId);
}