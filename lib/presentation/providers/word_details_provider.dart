import 'package:flutter/foundation.dart';

import '../../core/utils/result.dart';
import '../../domain/entities/word_entity.dart';
import '../../domain/repositories/favorite_repository.dart';
import '../../domain/repositories/word_repository.dart';

enum DetailsStatus { loading, success, notFound, error }

/// Drives the Word Details screen. Owns the full offline-first lookup
/// flow (via WordRepository.getWordDetails) and favorite-toggle state
/// for the currently displayed word.
class WordDetailsProvider extends ChangeNotifier {
  WordDetailsProvider({
    required WordRepository wordRepository,
    required FavoriteRepository favoriteRepository,
  })  : _wordRepository = wordRepository,
        _favoriteRepository = favoriteRepository;

  final WordRepository _wordRepository;
  final FavoriteRepository _favoriteRepository;

  DetailsStatus _status = DetailsStatus.loading;
  WordEntity? _word;
  bool _isFavorite = false;
  String? _errorMessage;
  bool _wasEnrichedFromApi = false;

  DetailsStatus get status => _status;
  WordEntity? get word => _word;
  bool get isFavorite => _isFavorite;
  String? get errorMessage => _errorMessage;
  bool get wasEnrichedFromApi => _wasEnrichedFromApi;

  Future<void> loadWord(String englishOrBangla) async {
    _status = DetailsStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final bool wasAlreadySynced = _word?.isSynced ?? false;

    final result = await _wordRepository.getWordDetails(englishOrBangla);

    result.when(
      success: (entity) {
        _word = entity;
        _wasEnrichedFromApi = entity.isSynced && !wasAlreadySynced;
        _status = DetailsStatus.success;
        _isFavorite = false; // refreshed below
      },
      failure: (message, cause) {
        _word = null;
        _errorMessage = message;
        _status = message.toLowerCase().contains('not found')
            ? DetailsStatus.notFound
            : DetailsStatus.error;
      },
    );

    if (_word?.id != null) {
      _isFavorite = await _favoriteRepository.isFavorite(_word!.id!);
      await _wordRepository.incrementSearchCount(_word!.id!);
    }

    notifyListeners();
  }

  Future<void> toggleFavorite() async {
    final currentWord = _word;
    if (currentWord?.id == null) return;

    final newState = !_isFavorite;
    _isFavorite = newState; // optimistic update
    notifyListeners();

    try {
      await _favoriteRepository.toggleFavorite(currentWord!.id!, newState);
    } catch (e) {
      _isFavorite = !newState; // revert on failure
      notifyListeners();
    }
  }

  void reset() {
    _status = DetailsStatus.loading;
    _word = null;
    _isFavorite = false;
    _errorMessage = null;
    _wasEnrichedFromApi = false;
  }
}