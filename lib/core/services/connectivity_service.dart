import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Thin wrapper around connectivity_plus, exposing a simple boolean
/// online/offline API plus a stream for reactive UI (offline banners,
/// Settings > API Sync Status). Kept in core/services (not data/) since
/// it's a cross-cutting device capability, not a data source.
class ConnectivityService {
  ConnectivityService() {
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      _controller.add(_isConnected(results));
    });
  }

  final _controller = StreamController<bool>.broadcast();
  late final StreamSubscription<List<ConnectivityResult>> _subscription;

  Stream<bool> get onStatusChange => _controller.stream;

  bool _isConnected(List<ConnectivityResult> results) {
    return results.any((r) => r != ConnectivityResult.none);
  }

  /// One-shot check — used by WordRepositoryImpl before deciding
  /// whether to attempt an API call (Step 7).
  ///
  /// Note: this confirms network *interface* availability (wifi/mobile
  /// data present), not actual internet reachability. Combined with
  /// the timeout + SocketException handling in DictionaryApiServiceImpl
  /// (Step 8), this two-layer check is intentional: a fast local check
  /// avoids attempting API calls when we know we're offline, while the
  /// HTTP layer still handles the "connected to wifi but no internet"
  /// edge case gracefully rather than assuming this check is infallible.
  Future<bool> isOnline() async {
    final results = await Connectivity().checkConnectivity();
    return _isConnected(results);
  }

  void dispose() {
    _subscription.cancel();
    _controller.close();
  }
}