import 'package:flutter/foundation.dart';

import '../../core/services/sync_status_service.dart';

/// Wraps SyncStatusService's raw stream into ChangeNotifier state so
/// Settings > API Sync Status can use context.watch() like every
/// other screen, instead of a one-off StreamBuilder.
class SyncStatusProvider extends ChangeNotifier {
  SyncStatusProvider(this._syncStatusService) {
    _syncStatusService.stream.listen((update) {
      _lastUpdate = update;
      notifyListeners();
    });
  }

  final SyncStatusService _syncStatusService;
  SyncStatusUpdate _lastUpdate = const SyncStatusUpdate(SyncEvent.idle);

  SyncStatusUpdate get lastUpdate => _lastUpdate;
  SyncEvent get event => _lastUpdate.event;
}