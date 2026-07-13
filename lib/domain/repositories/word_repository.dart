import '../../core/utils/result.dart';
import '../entities/word_entity.dart';

/// Contract for all word lookup, search, and enrichment operations.
/// This is the single entry point the presentation layer uses for
/// dictionary data — it internally coordinates local SQLite and the
/// remote API per the offline-first flow defined in the architecture.
abstract class WordRepository {
  /// Local-first, instant search-as-you-type suggestions. Never hits
  /// the network — this must be fast (<50ms typical) since it's called
  /// on every keystroke.
  Future<List<WordEntity>> searchLocal(String query, {int limit = 30});

  /// Full lookup flow per the offline-first pipeline (Step 1.2):
  /// checks local SQLite first; if online and the local entry is
  /// missing/incomplete, enriches from the API and persists the result.
  /// Returns a [Result] so the UI can distinguish "not found" from
  /// "network error" from "success".
  Future<Result<WordEntity>> getWordDetails(String english);

  Future<WordEntity?> getWordById(int id);

  Future<List<WordEntity>> getByCategory(int categoryId);

  Future<List<WordEntity>> getMostSearched({int limit = 10});

  Future<WordEntity?> getDailyWord(int seed);

  Future<void> incrementSearchCount(int wordId);

  Future<int> getTotalWordCount();

  Future<int> getSyncedWordCount();
}