import 'package:flutter/foundation.dart';

import '../../domain/entities/word_entity.dart';
import '../../domain/repositories/favorite_repository.dart';

enum LoadStatus { loading, success, empty, error }

class FavoritesProvider extends ChangeNotifier {
  FavoritesProvider(this._favoriteRepository);
  final FavoriteRepository _favoriteRepository;

  LoadStatus _status = LoadStatus.loading;
  List<WordEntity> _favorites = [];

  LoadStatus get status => _status;
  List<WordEntity> get favorites => _favorites;

  Future<void> loadFavorites() async {
    _status = LoadStatus.loading;
    notifyListeners();

    try {
      _favorites = await _favoriteRepository.getAllFavorites();
      _status = _favorites.isEmpty ? LoadStatus.empty : LoadStatus.success;
    } catch (e) {
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  /// Allows removing a favorite directly from the Favorites list
  /// screen (e.g. swipe-to-delete) without navigating to Word Details.
  Future<void> removeFavorite(int wordId) async {
    final previous = List<WordEntity>.from(_favorites);
    _favorites.removeWhere((w) => w.id == wordId); // optimistic
    if (_favorites.isEmpty) _status = LoadStatus.empty;
    notifyListeners();

    try {
      await _favoriteRepository.toggleFavorite(wordId, false);
    } catch (e) {
      _favorites = previous; // revert
      _status = LoadStatus.success;
      notifyListeners();
    }
  }
}