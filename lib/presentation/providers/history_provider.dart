import 'package:flutter/foundation.dart';

import '../../domain/entities/history_entity.dart';
import '../../domain/repositories/history_repository.dart';

import '../../core/enums/load_status.dart';

class HistoryProvider extends ChangeNotifier {
  HistoryProvider(this._historyRepository);
  final HistoryRepository _historyRepository;

  LoadStatus _status = LoadStatus.loading;
  List<HistoryEntity> _history = [];

  LoadStatus get status => _status;
  List<HistoryEntity> get history => _history;

  Future<void> loadHistory() async {
    _status = LoadStatus.loading;
    notifyListeners();

    try {
      _history = await _historyRepository.getRecentHistory();
      _status = _history.isEmpty ? LoadStatus.empty : LoadStatus.success;
    } catch (e) {
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> deleteEntry(int id) async {
    final previous = List<HistoryEntity>.from(_history);
    _history.removeWhere((h) => h.id == id);
    if (_history.isEmpty) _status = LoadStatus.empty;
    notifyListeners();

    try {
      await _historyRepository.deleteEntry(id);
    } catch (e) {
      _history = previous;
      _status = LoadStatus.success;
      notifyListeners();
    }
  }

  Future<void> clearAll() async {
    final previous = List<HistoryEntity>.from(_history);
    _history = [];
    _status = LoadStatus.empty;
    notifyListeners();

    try {
      await _historyRepository.clearAll();
    } catch (e) {
      _history = previous;
      _status = previous.isEmpty ? LoadStatus.empty : LoadStatus.success;
      notifyListeners();
    }
  }
}
