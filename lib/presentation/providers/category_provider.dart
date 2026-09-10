import 'package:flutter/foundation.dart';

import '../../domain/entities/category_entity.dart';
import '../../domain/entities/word_entity.dart';
import '../../domain/repositories/category_repository.dart';
import '../../core/enums/load_status.dart';

class CategoryProvider extends ChangeNotifier {
  CategoryProvider(this._categoryRepository);
  final CategoryRepository _categoryRepository;

  LoadStatus _categoriesStatus = LoadStatus.loading;
  List<CategoryEntity> _categories = [];

  LoadStatus _wordsStatus = LoadStatus.loading;
  List<WordEntity> _categoryWords = [];
  CategoryEntity? _selectedCategory;

  LoadStatus get categoriesStatus => _categoriesStatus;
  List<CategoryEntity> get categories => _categories;

  LoadStatus get wordsStatus => _wordsStatus;
  List<WordEntity> get categoryWords => _categoryWords;
  CategoryEntity? get selectedCategory => _selectedCategory;

  Future<void> loadCategories() async {
    _categoriesStatus = LoadStatus.loading;
    notifyListeners();

    try {
      _categories = await _categoryRepository.getAllCategories();
      _categoriesStatus =
          _categories.isEmpty ? LoadStatus.empty : LoadStatus.success;
    } catch (e) {
      _categoriesStatus = LoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> loadWordsForCategory(CategoryEntity category) async {
    _selectedCategory = category;
    _wordsStatus = LoadStatus.loading;
    notifyListeners();

    try {
      _categoryWords =
          await _categoryRepository.getWordsInCategory(category.id!);
      _wordsStatus =
          _categoryWords.isEmpty ? LoadStatus.empty : LoadStatus.success;
    } catch (e) {
      _wordsStatus = LoadStatus.error;
    }
    notifyListeners();
  }
}
