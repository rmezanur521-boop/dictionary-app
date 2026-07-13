import 'dart:async';

/// Simple debounce utility — delays execution until [milliseconds]
/// have passed without a new call. Used by SearchProvider to avoid
/// running a SQLite query on every single keystroke.
class Debouncer {
  Debouncer({this.milliseconds = 300});
  final int milliseconds;
  Timer? _timer;

  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void dispose() {
    _timer?.cancel();
  }
}