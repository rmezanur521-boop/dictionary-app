import '../../domain/entities/word_entity.dart';
import '../../domain/repositories/favorite_repository.dart';
import '../local/daos/favorite_dao.dart';
import '../models/favorite_model.dart';

class FavoriteRepositoryImpl implements FavoriteRepository {
  FavoriteRepositoryImpl(this._favoriteDao);
  final FavoriteDao _favoriteDao;

  @override
  Future<bool> isFavorite(int wordId) => _favoriteDao.isFavorite(wordId);

  @override
  Future<void> toggleFavorite(int wordId, bool shouldBeFavorite) async {
    if (shouldBeFavorite) {
      await _favoriteDao.add(FavoriteModel(wordId: wordId, addedAt: DateTime.now()));
    } else {
      await _favoriteDao.removeByWordId(wordId);
    }
  }

  @override
  Future<List<WordEntity>> getAllFavorites() => _favoriteDao.getAllFavoriteWords();

  @override
  Future<int> getFavoriteCount() => _favoriteDao.getCount();
}