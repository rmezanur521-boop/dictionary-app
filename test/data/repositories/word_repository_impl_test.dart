import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:dictionary_app/core/services/connectivity_service.dart';
import 'package:dictionary_app/core/services/sync_status_service.dart';
import 'package:dictionary_app/core/utils/result.dart';
import 'package:dictionary_app/data/local/daos/cached_api_dao.dart';
import 'package:dictionary_app/data/local/daos/word_dao.dart';
import 'package:dictionary_app/data/models/word_model.dart';
import 'package:dictionary_app/data/remote/dictionary_api_service.dart';
import 'package:dictionary_app/data/repositories/word_repository_impl.dart';

import 'word_repository_impl_test.mocks.dart';

@GenerateMocks([WordDao, CachedApiDao, DictionaryApiService, ConnectivityService])
void main() {
  late MockWordDao wordDao;
  late MockCachedApiDao cachedApiDao;
  late MockDictionaryApiService apiService;
  late MockConnectivityService connectivityService;
  late WordRepositoryImpl repository;

  setUp(() {
    wordDao = MockWordDao();
    cachedApiDao = MockCachedApiDao();
    apiService = MockDictionaryApiService();
    connectivityService = MockConnectivityService();
    repository = WordRepositoryImpl(
      wordDao: wordDao,
      cachedApiDao: cachedApiDao,
      apiService: apiService,
      connectivityService: connectivityService,
      syncStatusService: SyncStatusService(),
    );
  });

  group('getWordDetails — offline-first pipeline', () {
    test('returns local data immediately when word is already enrichment-complete', () async {
      final complete = WordModel(
        id: 1,
        english: 'apple',
        bangla: 'আপেল',
        phonetics: '/ˈæpl/',
        example: 'I ate an apple.',
        synonyms: const ['fruit'],
        isSynced: true,
      );
      when(wordDao.getByExactEnglish('apple')).thenAnswer((_) async => complete);
      when(connectivityService.isOnline()).thenAnswer((_) async => true);

      final result = await repository.getWordDetails('apple');

      expect(result.isSuccess, true);
      verifyNever(apiService.fetchWordData(any));
    });

    test('returns graceful failure when offline and word not found locally', () async {
      when(wordDao.getByExactEnglish('unknownword')).thenAnswer((_) async => null);
      when(wordDao.getByExactBangla('unknownword')).thenAnswer((_) async => null);
      when(connectivityService.isOnline()).thenAnswer((_) async => false);

      final result = await repository.getWordDetails('unknownword');

      expect(result.isSuccess, false);
      result.when(
        success: (_) => fail('should not succeed'),
        failure: (message, _) => expect(message, contains('offline')),
      );
    });

    test('enriches incomplete local word from API when online', () async {
      final incomplete = WordModel(id: 2, english: 'run', bangla: 'দৌড়ানো');
      when(wordDao.getByExactEnglish('run')).thenAnswer((_) async => incomplete);
      when(connectivityService.isOnline()).thenAnswer((_) async => true);
      when(apiService.fetchWordData('run')).thenAnswer((_) async => Result.success({
            'word': 'run',
            'phonetic': '/rʌn/',
            'meanings': [
              {
                'partOfSpeech': 'verb',
                'definitions': [
                  {'definition': 'move fast', 'example': 'He runs daily.', 'synonyms': ['sprint'], 'antonyms': ['walk']}
                ],
              }
            ],
          }));
      when(wordDao.updateEnrichment(any)).thenAnswer((_) async => 1);
      when(cachedApiDao.save(any)).thenAnswer((_) async {});

      final result = await repository.getWordDetails('run');

      expect(result.isSuccess, true);
      verify(wordDao.updateEnrichment(any)).called(1);
      // Duplicate-prevention guarantee: cache save called exactly once.
      verify(cachedApiDao.save(any)).called(1);
    });

    test('falls back to incomplete local data if API fails, rather than hard error', () async {
      final incomplete = WordModel(id: 3, english: 'jog', bangla: 'জগিং');
      when(wordDao.getByExactEnglish('jog')).thenAnswer((_) async => incomplete);
      when(connectivityService.isOnline()).thenAnswer((_) async => true);
      when(apiService.fetchWordData('jog'))
          .thenAnswer((_) async => const Result.failure('No internet connection.'));

      final result = await repository.getWordDetails('jog');

      expect(result.isSuccess, true); // graceful degradation, not a failure
      result.when(
        success: (word) => expect(word.english, 'jog'),
        failure: (_, __) => fail('should have fallen back to local data'),
      );
    });
  });
}