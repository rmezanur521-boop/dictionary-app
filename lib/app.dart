import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/screens/splash/splash_screen.dart';

/// Root widget: owns MaterialApp, theme binding, and route generation.
/// The bottom-nav shell (MainShell) is NOT set as `home` directly —
/// SplashScreen is, since it owns first-run DB initialization checks
/// and daily-word/deep-link warm-up before handing off to the shell.
class DictionaryApp extends StatelessWidget {
  const DictionaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'অভিধান — EN-BN Dictionary',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: const SplashScreen(),
    );
  }
}