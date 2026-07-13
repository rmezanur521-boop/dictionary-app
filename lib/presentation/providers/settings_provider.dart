import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../data/local/database_helper.dart';
import '../../domain/repositories/history_repository.dart';
import '../../domain/repositories/word_repository.dart';

/// Backs the Settings screen: database info, sync stats, app version,
/// and history clearing. Deliberately reads directly from
/// WordRepository/HistoryRepository/DatabaseHelper — no new repository
/// needed since this is purely aggregating existing data for display.
class SettingsProvider extends ChangeNotifier {
  SettingsProvider({
    required WordRepository wordRepository,
    required HistoryRepository historyRepository,
    required DatabaseHelper dbHelper,
  })  : _wordRepository = wordRepository,
        _historyRepository = historyRepository,
        _dbHelper = dbHelper;

  final WordRepository _wordRepository;
  final HistoryRepository _historyRepository;
  final DatabaseHelper _dbHelper;

  bool _isLoading = true;
  int _totalWords = 0;
  int _syncedWords = 0;
  int _dbSizeBytes = 0;
  String _appVersion = '';
  DateTime? _lastSyncAt;

  bool get isLoading => _isLoading;
  int get totalWords => _totalWords;
  int get syncedWords => _syncedWords;
  double get syncPercentage => _totalWords == 0 ? 0 : (_syncedWords / _totalWords) * 100;
  String get dbSizeFormatted => _formatBytes(_dbSizeBytes);
  String get appVersion => _appVersion;
  DateTime? get lastSyncAt => _lastSyncAt;

  Future<void> loadSettingsInfo() async {
    _isLoading = true;
    notifyListeners();

    _totalWords = await _wordRepository.getTotalWordCount();
    _syncedWords = await _wordRepository.getSyncedWordCount();
    _dbSizeBytes = await _dbHelper.getDatabaseSizeInBytes();

    final packageInfo = await PackageInfo.fromPlatform();
    _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';

    final prefs = await SharedPreferences.getInstance();
    final lastSyncStr = prefs.getString(AppConstants.prefLastSyncAt);
    _lastSyncAt = lastSyncStr != null ? DateTime.tryParse(lastSyncStr) : null;

    _isLoading = false;
    notifyListeners();
  }

  Future<void> clearSearchHistory() async {
    await _historyRepository.clearAll();
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(size < 10 ? 1 : 0)} ${suffixes[i]}';
  }
}