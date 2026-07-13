import 'package:flutter/foundation.dart';

import '../../core/services/connectivity_service.dart';

/// Exposes real-time online/offline state to the whole widget tree.
/// Used for the offline banner (core widget), Search screen behavior
/// hints, and Settings > API Sync Status.
class ConnectivityProvider extends ChangeNotifier {
  ConnectivityProvider(this._connectivityService) {
    _init();
  }

  final ConnectivityService _connectivityService;
  bool _isOnline = true;

  bool get isOnline => _isOnline;

  Future<void> _init() async {
    _isOnline = await _connectivityService.isOnline();
    notifyListeners();
    _connectivityService.onStatusChange.listen((online) {
      if (_isOnline != online) {
        _isOnline = online;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _connectivityService.dispose();
    super.dispose();
  }
}