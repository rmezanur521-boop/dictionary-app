import '../../domain/entities/category_entity.dart';
import '../../domain/entities/word_entity.dart';
import '../../domain/repositories/category_repository.dart';
import '../local/daos/category_dao.dart';
import '../local/daos/word_dao.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl(this._categoryDao, this._wordDao);
  final CategoryDao _categoryDao;
  final WordDao _wordDao;

  @override
  Future<List<CategoryEntity>> getAllCategories() => _categoryDao.getAll();

  @override
  Future<List<WordEntity>> getWordsInCategory(int categoryId) => _wordDao.getByCategory(categoryId);
}