import 'package:flutter/foundation.dart';

import '../../domain/entities/word_entity.dart';
import '../../domain/repositories/favorite_repository.dart';
import '../../core/enums/load_status.dart';

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
  ///
  /// Returns the removed [WordEntity] on success so the caller (UI) can
  /// offer an "Undo" action via [restoreFavorite]. Returns `null` if the
  /// word wasn't found in the current favorites list.
  Future<WordEntity?> removeFavorite(int wordId) async {
    final previous = List<WordEntity>.from(_favorites);
    WordEntity? removed;
    for (final w in previous) {
      if (w.id == wordId) {
        removed = w;
        break;
      }
    }
    if (removed == null) return null;

    _favorites.removeWhere((w) => w.id == wordId); // optimistic
    if (_favorites.isEmpty) _status = LoadStatus.empty;
    notifyListeners();

    try {
      await _favoriteRepository.toggleFavorite(wordId, false);
      return removed;
    } catch (e) {
      _favorites = previous; // revert
      _status = LoadStatus.success;
      notifyListeners();
      return null;
    }
  }

  /// Re-adds a previously removed favorite (used for the Undo action in
  /// [removeFavorite]'s snackbar).
  Future<void> restoreFavorite(WordEntity word) async {
    if (word.id == null) return;
    if (_favorites.any((w) => w.id == word.id)) return; // already present

    final previous = List<WordEntity>.from(_favorites);
    _favorites = [word, ..._favorites]; // optimistic
    _status = LoadStatus.success;
    notifyListeners();

    try {
      await _favoriteRepository.toggleFavorite(word.id!, true);
    } catch (e) {
      _favorites = previous; // revert
      if (_favorites.isEmpty) _status = LoadStatus.empty;
      notifyListeners();
    }
  }
}
