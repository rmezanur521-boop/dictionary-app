import '../entities/word_entity.dart';

abstract class FavoriteRepository {
  Future<bool> isFavorite(int wordId);
  Future<void> toggleFavorite(int wordId, bool shouldBeFavorite);
  Future<List<WordEntity>> getAllFavorites();
  Future<int> getFavoriteCount();
}