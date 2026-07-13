import 'dart:async';

enum SyncEvent { idle, syncing, success, failed }

class SyncStatusUpdate {
  final SyncEvent event;
  final String? wordBeingSynced;
  final String? message;

  const SyncStatusUpdate(this.event, {this.wordBeingSynced, this.message});
}

/// Broadcasts live sync activity so any part of the UI (Settings >
/// API Sync Status, a future in-app toast/indicator) can reactively
/// show "syncing 'apple'..." / "synced" / "sync failed" without
/// polling. This is intentionally a plain broadcaster, not a
/// ChangeNotifier — it's consumed as a Stream via StreamBuilder where
/// needed, since sync events are transient pulses, not persistent
/// state a whole Provider tree needs to rebuild around.
class SyncStatusService {
  final _controller = StreamController<SyncStatusUpdate>.broadcast();

  Stream<SyncStatusUpdate> get stream => _controller.stream;

  void emitSyncing(String word) {
    _controller.add(SyncStatusUpdate(SyncEvent.syncing, wordBeingSynced: word));
  }

  void emitSuccess(String word) {
    _controller.add(SyncStatusUpdate(SyncEvent.success, wordBeingSynced: word));
  }

  void emitFailed(String word, String message) {
    _controller.add(SyncStatusUpdate(SyncEvent.failed, wordBeingSynced: word, message: message));
  }

  void dispose() => _controller.close();
}