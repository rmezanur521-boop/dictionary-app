import 'package:flutter/material.dart';

/// Brand seed colors and any colors that fall outside Material 3's
/// auto-generated ColorScheme (e.g. semantic colors for sync status).
/// Everything else should come from Theme.of(context).colorScheme —
/// avoid hardcoding colors in widgets.
class AppColors {
  AppColors._();

  /// Deep indigo/teal-leaning seed — evokes "book/ink" without being
  /// a cliché brown/sepia library theme. Feeds Material 3's tonal
  /// palette generation for both light and dark schemes.
  static const Color seed = Color(0xFF2D5F6D);

  // Semantic colors (status indicators), intentionally outside the
  // generated ColorScheme since they carry fixed meaning regardless
  // of theme brightness.
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF9A825);
  static const Color offline = Color(0xFF9E9E9E);
}