import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/sync_status_service.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/word_entity.dart';
import '../../domain/repositories/word_repository.dart';
import '../local/daos/cached_api_dao.dart';
import '../local/daos/word_dao.dart';
import '../models/cached_api_model.dart';
import '../models/word_model.dart';
import '../remote/dictionary_api_service.dart';

/// Implements the offline-first pipeline: local SQLite is always
/// checked first and is the source of truth for the UI; the remote
/// API is only ever used to enrich/fill gaps, and only when the
/// device is online AND the word isn't already enrichment-complete.
///
/// DUPLICATE-PREVENTION GUARANTEE (verify against this comment when
/// reviewing sync behavior):
///   1. Application-level: `WordEntity.isEnrichmentComplete` short-
///      circuits before any API call is attempted for a word that
///      already has phonetics + example + synonyms.
///   2. Schema-level: `cached_api_data.word_id` has a UNIQUE
///      constraint (Step 4); `CachedApiDao.save` uses
///      ConflictAlgorithm.replace, so even a bug in (1) could not
///      produce a second cached-response ROW for the same word — it
///      would overwrite, not duplicate.
///   Both layers exist because relying on application logic alone is
///   fragile against future code changes; the schema constraint is
///   the actual, unbypassable guarantee.
class WordRepositoryImpl implements WordRepository {
  WordRepositoryImpl({
    required WordDao wordDao,
    required CachedApiDao cachedApiDao,
    required DictionaryApiService apiService,
    required ConnectivityService connectivityService,
    required SyncStatusService syncStatusService,
  })  : _wordDao = wordDao,
        _cachedApiDao = cachedApiDao,
        _apiService = apiService,
        _connectivityService = connectivityService,
        _syncStatusService = syncStatusService;

  final WordDao _wordDao;
  final CachedApiDao _cachedApiDao;
  final DictionaryApiService _apiService;
  final ConnectivityService _connectivityService;
  final SyncStatusService _syncStatusService;

  @override
  Future<List<WordEntity>> searchLocal(String query, {int limit = 30}) {
    return _wordDao.search(query: query, limit: limit);
  }

  @override
  Future<Result<WordEntity>> getWordDetails(String english) async {
    final trimmed = english.trim();
    if (trimmed.isEmpty) {
      return const Result.failure('Empty search query');
    }

    // 1. Local SQLite first — always, regardless of connectivity.
    WordModel? local = await _wordDao.getByExactEnglish(trimmed);
    local ??= await _wordDao.getByExactBangla(trimmed);

    final bool isOnline = await _connectivityService.isOnline();

    // 2a. Complete locally, or offline entirely -> return local as-is.
    //     This is the enforcement point for "never download duplicate
    //     data": isEnrichmentComplete==true means we never even ask.
    if (local != null && (local.isEnrichmentComplete || !isOnline)) {
      return Result.success(local);
    }

    // 2b. Nothing local, and offline -> graceful, explicit failure.
    if (local == null && !isOnline) {
      return const Result.failure(
        'Word not found offline. Connect to the internet to search online.',
      );
    }

    // 3. Online enrichment path (new word OR incomplete local word).
    return _fetchAndPersistFromApi(trimmed, local);
  }

  Future<Result<WordEntity>> _fetchAndPersistFromApi(String trimmed, WordModel? local) async {
    _syncStatusService.emitSyncing(trimmed);

    final apiResult = await _fetchWithRetry(trimmed);

    return apiResult.when(
      success: (json) async {
        final enriched = local != null
            ? WordModel.mergeApiEnrichment(localWord: local, apiEntry: json)
            : _buildNewWordFromApiOnly(trimmed, json);

        await _persistEnrichment(enriched, rawJson: json);
        await _recordSyncTimestamp();

        _syncStatusService.emitSuccess(trimmed);
        return Result.success(enriched);
      },
      failure: (message, cause) async {
        _syncStatusService.emitFailed(trimmed, message);

        // Graceful degradation: an incomplete local copy is still
        // better than a hard failure — show what we have.
        if (local != null) return Result.success(local);
        return Result.failure('Word not found. $message');
      },
    );
  }

  /// One retry for transient failures only (timeout / generic network
  /// hiccup) — NOT for deterministic failures like 404 (word genuinely
  /// doesn't exist) or malformed responses, where retrying is pointless
  /// and just wastes time/battery. This distinction is why we inspect
  /// the failure message rather than blindly retrying every failure.
  Future<Result<Map<String, dynamic>>> _fetchWithRetry(String word) async {
    final first = await _apiService.fetchWordData(word);
    if (first.isSuccess) return first;

    final isTransient = first.when(
      success: (_) => false,
      failure: (message, cause) =>
          message.contains('timed out') || message.contains('unexpected error'),
    );

    if (!isTransient) return first;

    // Single retry, no exponential backoff needed for a one-shot
    // lookup triggered by direct user action (not a background job
    // where repeated backoff would matter more).
    return _apiService.fetchWordData(word);
  }

  WordModel _buildNewWordFromApiOnly(String english, Map<String, dynamic> json) {
    final placeholder = WordModel(english: english, bangla: '');
    return WordModel.mergeApiEnrichment(localWord: placeholder, apiEntry: json);
  }

  Future<void> _persistEnrichment(WordModel word, {required Map<String, dynamic> rawJson}) async {
    int wordId;
    if (word.id == null) {
      wordId = await _wordDao.insert(word);
    } else {
      wordId = word.id!;
      await _wordDao.updateEnrichment(word);
    }

    await _cachedApiDao.save(CachedApiModel(
      wordId: wordId,
      rawJson: jsonEncode(rawJson),
      fetchedAt: DateTime.now(),
    ));
  }

  Future<void> _recordSyncTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefLastSyncAt, DateTime.now().toIso8601String());
  }

  @override
  Future<WordEntity?> getWordById(int id) => _wordDao.getById(id);

  @override
  Future<List<WordEntity>> getByCategory(int categoryId) => _wordDao.getByCategory(categoryId);

  @override
  Future<List<WordEntity>> getMostSearched({int limit = 10}) => _wordDao.getMostSearched(limit: limit);

  @override
  Future<WordEntity?> getDailyWord(int seed) => _wordDao.getRandomWord(seed: seed);

  @override
  Future<void> incrementSearchCount(int wordId) => _wordDao.incrementSearchCount(wordId);

  @override
  Future<int> getTotalWordCount() => _wordDao.getTotalWordCount();

  @override
  Future<int> getSyncedWordCount() => _wordDao.getSyncedWordCount();
}