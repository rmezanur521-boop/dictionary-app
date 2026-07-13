import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/local/database_helper.dart';
import '../main_shell.dart';

/// First screen shown on app launch. Performs the one-time critical
/// warm-up step — ensuring the SQLite database (either the preloaded
/// 50k-word asset or the fallback empty schema, per DatabaseHelper's
/// graceful-degradation logic) is fully opened and ready — before
/// handing off to the main navigation shell. This prevents a jarring
/// "flash of empty search results" if the DB were still initializing
/// when Home/Search first render.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final stopwatch = Stopwatch()..start();

    // Triggers DatabaseHelper's lazy singleton init (asset copy on
    // first run, or open existing DB on subsequent runs).
    await DatabaseHelper.instance.database;

    // Enforce a minimum splash duration so the branding is visible
    // even on fast devices where DB open takes <100ms — avoids an
    // unpleasant "flash" of the splash screen.
    const minimumDuration = Duration(milliseconds: 900);
    final elapsed = stopwatch.elapsed;
    if (elapsed < minimumDuration) {
      await Future.delayed(minimumDuration - elapsed);
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(Icons.menu_book_rounded, size: 48, color: colorScheme.onPrimaryContainer),
            ),
            const SizedBox(height: 24),
            Text(AppConstants.appName, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'English ⇄ বাংলা Dictionary',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: colorScheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}