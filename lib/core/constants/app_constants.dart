class AppConstants {
  AppConstants._();

  static const String appName = 'অভিধান — EN-BN Dictionary';
  static const String dbName = 'dictionary_app.db';
  static const String seedDbAssetPath = 'assets/db/dictionary_preloaded.db';
  static const int dbVersion = 1;

  // SharedPreferences keys
  static const String prefThemeMode = 'pref_theme_mode';
  static const String prefIsFirstRun = 'pref_is_first_run';
  static const String prefLastSyncAt = 'pref_last_sync_at';
  static const String prefDailyWordDate = 'pref_daily_word_date';
  static const String prefDailyWordId = 'pref_daily_word_id';
}