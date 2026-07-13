import '../../domain/entities/history_entity.dart';
import '../../domain/repositories/history_repository.dart';
import '../local/daos/history_dao.dart';
import '../models/history_model.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  HistoryRepositoryImpl(this._historyDao);
  final HistoryDao _historyDao;

  @override
  Future<void> recordSearch({
    required String query,
    int? wordId,
    required SearchLanguage language,
  }) async {
    await _historyDao.insert(HistoryModel(
      query: query.trim(),
      wordId: wordId,
      searchedAt: DateTime.now(),
      language: language,
    ));
  }

  @override
  Future<List<HistoryEntity>> getRecentHistory({int limit = 100}) async {
    final rows = await _historyDao.getRecent(limit: limit);
    return rows.map((row) {
      final model = HistoryModel.fromMap(row);
      return model;
    }).toList();
  }

  @override
  Future<void> deleteEntry(int id) => _historyDao.deleteById(id);

  @override
  Future<void> clearAll() => _historyDao.clearAll();
}