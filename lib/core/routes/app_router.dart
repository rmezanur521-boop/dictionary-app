import 'package:flutter/material.dart';

import '../../domain/entities/category_entity.dart';
import '../../presentation/screens/about/about_screen.dart';
import '../../presentation/screens/categories/category_words_screen.dart';
import '../../presentation/screens/daily_word/daily_word_screen.dart';
import '../../presentation/screens/history/history_screen.dart';
import '../../presentation/screens/word_details/word_details_screen.dart';

/// Centralized route name constants + generator. Screens never
/// hardcode a route string inline (Navigator.pushNamed('/word-details')
/// scattered everywhere is a common source of typo bugs) — they use
/// these constants and, where args are required, the typed helper
/// methods below.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String shell =
      '/'; // bottom-nav host (Home/Search/Favorites/Categories/Settings)
  static const String wordDetails = '/word-details';
  static const String categoryWords = '/category-words';
  static const String history = '/history';
  static const String dailyWord = '/daily-word';
  static const String about = '/about';
}

class AppRouter {
  AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.wordDetails:
        final query = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => WordDetailsScreen(searchTerm: query),
          settings: settings,
        );

      case AppRoutes.categoryWords:
        final category = settings.arguments as CategoryEntity;
        return MaterialPageRoute(
          builder: (_) => CategoryWordsScreen(category: category),
          settings: settings,
        );

      case AppRoutes.history:
        return MaterialPageRoute(
            builder: (_) => const HistoryScreen(), settings: settings);

      case AppRoutes.dailyWord:
        return MaterialPageRoute(
            builder: (_) => const DailyWordScreen(), settings: settings);

      case AppRoutes.about:
        return MaterialPageRoute(
            builder: (_) => const AboutScreen(), settings: settings);

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Route not found: ${settings.name}')),
          ),
        );
    }
  }

  /// Typed navigation helpers — prevents callers from passing the
  /// wrong argument type/shape to pushNamed, which is a common
  /// runtime-only bug with string-based routing.
  static Future<void> openWordDetails(BuildContext context, String searchTerm) {
    return Navigator.of(context)
        .pushNamed(AppRoutes.wordDetails, arguments: searchTerm);
  }

  static Future<void> openCategoryWords(
      BuildContext context, CategoryEntity category) {
    return Navigator.of(context)
        .pushNamed(AppRoutes.categoryWords, arguments: category);
  }

  static Future<void> openHistory(BuildContext context) {
    return Navigator.of(context).pushNamed(AppRoutes.history);
  }

  static Future<void> openDailyWord(BuildContext context) {
    return Navigator.of(context).pushNamed(AppRoutes.dailyWord);
  }

  static Future<void> openAbout(BuildContext context) {
    return Navigator.of(context).pushNamed(AppRoutes.about);
  }
}
