import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/tts_service.dart';
import 'data/local/daos/cached_api_dao.dart';
import 'data/local/daos/category_dao.dart';
import 'data/local/daos/favorite_dao.dart';
import 'data/local/daos/history_dao.dart';
import 'data/local/daos/word_dao.dart';
import 'data/local/database_helper.dart';
import 'data/remote/dictionary_api_service.dart';
import 'data/repositories/category_repository_impl.dart';
import 'data/repositories/favorite_repository_impl.dart';
import 'data/repositories/history_repository_impl.dart';
import 'data/repositories/word_repository_impl.dart';
import 'domain/repositories/category_repository.dart';
import 'domain/repositories/favorite_repository.dart';
import 'domain/repositories/history_repository.dart';
import 'domain/repositories/word_repository.dart';
import 'presentation/providers/category_provider.dart';
import 'presentation/providers/connectivity_provider.dart';
import 'presentation/providers/daily_word_provider.dart';
import 'presentation/providers/favorites_provider.dart';
import 'presentation/providers/history_provider.dart';
import 'presentation/providers/search_provider.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/tts_provider.dart';
import 'presentation/providers/word_details_provider.dart';
import 'core/services/sync_status_service.dart';
import 'presentation/providers/sync_status_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Core singletons ──────────────────────────────────────────
  final dbHelper = DatabaseHelper.instance;
  final connectivityService = ConnectivityService();
  final ttsService = TtsService();
  final apiService = DictionaryApiServiceImpl();
  final syncStatusService = SyncStatusService();

  // ── DAOs ──────────────────────────────────────────────────────
  final wordDao = WordDao(dbHelper);
  final favoriteDao = FavoriteDao(dbHelper);
  final historyDao = HistoryDao(dbHelper);
  final categoryDao = CategoryDao(dbHelper);
  final cachedApiDao = CachedApiDao(dbHelper);

  // ── Repositories (bound to abstract types) ───────────────────
  final WordRepository wordRepository = WordRepositoryImpl(
    wordDao: wordDao,
    cachedApiDao: cachedApiDao,
    apiService: apiService,
    connectivityService: connectivityService,
    syncStatusService: syncStatusService,
  );
  final FavoriteRepository favoriteRepository = FavoriteRepositoryImpl(favoriteDao);
  final HistoryRepository historyRepository = HistoryRepositoryImpl(historyDao);
  final CategoryRepository categoryRepository = CategoryRepositoryImpl(categoryDao, wordDao);

  runApp(
    MultiProvider(
      providers: [
        // Core app-wide providers
        ChangeNotifierProvider(create: (_) => ThemeProvider()..loadSavedTheme()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider(connectivityService)),
        ChangeNotifierProvider(create: (_) => TtsProvider(ttsService)),
        ChangeNotifierProvider(create: (_) => SyncStatusProvider(syncStatusService)),

        // Feature providers — each depends only on a repository interface
        ChangeNotifierProvider(
          create: (_) => SearchProvider(wordRepository: wordRepository, historyRepository: historyRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => WordDetailsProvider(wordRepository: wordRepository, favoriteRepository: favoriteRepository),
        ),
        ChangeNotifierProvider(create: (_) => FavoritesProvider(favoriteRepository)),
        ChangeNotifierProvider(create: (_) => HistoryProvider(historyRepository)),
        ChangeNotifierProvider(create: (_) => CategoryProvider(categoryRepository)),
        ChangeNotifierProvider(create: (_) => DailyWordProvider(wordRepository)),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(wordRepository: wordRepository, historyRepository: historyRepository, dbHelper: dbHelper),
        ),
      ],
      child: const DictionaryApp(),
    ),
  );
}