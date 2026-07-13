import '../entities/history_entity.dart';

abstract class HistoryRepository {
  Future<void> recordSearch({
    required String query,
    int? wordId,
    required SearchLanguage language,
  });
  Future<List<HistoryEntity>> getRecentHistory({int limit = 100});
  Future<void> deleteEntry(int id);
  Future<void> clearAll();
}