import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/date_utils.dart';
import '../../domain/entities/word_entity.dart';
import '../../domain/repositories/word_repository.dart';
import '../../core/enums/load_status.dart';

class DailyWordProvider extends ChangeNotifier {
  DailyWordProvider(this._wordRepository);
  final WordRepository _wordRepository;

  LoadStatus _status = LoadStatus.loading;
  WordEntity? _dailyWord;

  LoadStatus get status => _status;
  WordEntity? get dailyWord => _dailyWord;

  Future<void> loadDailyWord() async {
    _status = LoadStatus.loading;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final todayKey = AppDateUtils.todayDateKey();
      final storedDate = prefs.getString(AppConstants.prefDailyWordDate);
      final storedWordId = prefs.getInt(AppConstants.prefDailyWordId);

      WordEntity? word;

      if (storedDate == todayKey && storedWordId != null) {
        // Same day, already chosen — reuse it for consistency.
        word = await _wordRepository.getWordById(storedWordId);
      }

      // Either a new day, or the previously stored word no longer
      // exists (edge case) — pick a new deterministic word for today.
      word ??= await _wordRepository.getDailyWord(AppDateUtils.todaySeed());

      if (word != null && word.id != null) {
        await prefs.setString(AppConstants.prefDailyWordDate, todayKey);
        await prefs.setInt(AppConstants.prefDailyWordId, word.id!);
      }

      _dailyWord = word;
      _status = word == null ? LoadStatus.empty : LoadStatus.success;
    } catch (e) {
      _status = LoadStatus.error;
    }
    notifyListeners();
  }
}
