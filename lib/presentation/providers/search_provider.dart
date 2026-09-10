import 'package:flutter/foundation.dart';

import '../../core/utils/debouncer.dart';
import '../../core/utils/language_detector.dart';
import '../../domain/entities/word_entity.dart';
import '../../domain/repositories/history_repository.dart';
import '../../domain/repositories/word_repository.dart';

enum SearchStatus { idle, loading, success, empty, error }

/// Drives the Search screen and the Home screen's quick-search bar.
/// Handles instant local suggestions (debounced) — the full lookup
/// (with API enrichment) is delegated to WordDetailsProvider once the
/// user actually selects a result, keeping this provider fast and
/// purely local per keystroke.
class SearchProvider extends ChangeNotifier {
  SearchProvider({
    required WordRepository wordRepository,
    required HistoryRepository historyRepository,
  })  : _wordRepository = wordRepository,
        _historyRepository = historyRepository;

  final WordRepository _wordRepository;
  final HistoryRepository _historyRepository;
  final Debouncer _debouncer = Debouncer(milliseconds: 250);

  String _query = '';
  SearchStatus _status = SearchStatus.idle;
  List<WordEntity> _suggestions = [];
  String? _errorMessage;

  String get query => _query;
  SearchStatus get status => _status;
  List<WordEntity> get suggestions => _suggestions;
  String? get errorMessage => _errorMessage;

  /// Called on every keystroke from the search bar. Debounced to avoid
  /// hammering SQLite on rapid typing; still fully local, so even the
  /// debounced call is near-instant on the UI thread.
  void onQueryChanged(String value) {
    _query = value;
    if (value.trim().isEmpty) {
      _suggestions = [];
      _status = SearchStatus.idle;
      notifyListeners();
      return;
    }

    _status = SearchStatus.loading;
    notifyListeners();

    _debouncer.run(() async {
      await _performSearch(value);
    });
  }

  Future<void> _performSearch(String value) async {
    try {
      final results = await _wordRepository.searchLocal(value);
      _suggestions = results;
      _status = results.isEmpty ? SearchStatus.empty : SearchStatus.success;
      _errorMessage = null;
    } catch (e) {
      _status = SearchStatus.error;
      _errorMessage = 'Search failed. Please try again.';
    }
    notifyListeners();
  }

  /// Records the search in history — called when the user commits to
  /// a result (taps a suggestion or presses "search"), not on every
  /// keystroke, to keep history meaningful rather than noisy.
  Future<void> recordSearch({int? wordId}) async {
    if (_query.trim().isEmpty) return;
    final detectedLang = LanguageDetector.detect(_query);
    await _historyRepository.recordSearch(
      query: _query.trim(),
      wordId: wordId,
      language: detectedLang,
    );
  }

  void clearQuery() {
    _query = '';
    _suggestions = [];
    _status = SearchStatus.idle;
    notifyListeners();
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }
}
