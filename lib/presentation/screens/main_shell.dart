import 'package:flutter/material.dart';

import 'categories/categories_screen.dart';
import 'favorites/favorites_screen.dart';
import 'home/home_screen.dart';
import 'search/search_screen.dart';
import 'settings/settings_screen.dart';

/// Minimal cross-tab navigation hook. Allows a screen hosted inside
/// one tab (e.g. HomeScreen) to request switching to a different tab
/// (e.g. Search) without tight coupling to MainShell's State object.
/// Intentionally lightweight for this app's scope — a full app-level
/// navigation service would be overkill for "switch bottom nav tab."
class MainShellTabController {
  static MainShellTabController? instance;

  final void Function(int index) switchToTab;

  MainShellTabController._(this.switchToTab);
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const List<Widget> _tabs = [
    HomeScreen(),
    SearchScreen(),
    FavoritesScreen(),
    CategoriesScreen(),
    SettingsScreen(),
  ];

  static const List<({IconData icon, IconData selectedIcon, String label})> _destinations = [
    (icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Home'),
    (icon: Icons.search_outlined, selectedIcon: Icons.search, label: 'Search'),
    (icon: Icons.favorite_outline, selectedIcon: Icons.favorite, label: 'Favorites'),
    (icon: Icons.category_outlined, selectedIcon: Icons.category, label: 'Categories'),
    (icon: Icons.settings_outlined, selectedIcon: Icons.settings, label: 'Settings'),
  ];

  @override
  void initState() {
    super.initState();
    MainShellTabController.instance = MainShellTabController._(
      (index) => setState(() => _currentIndex = index),
    );
  }

  @override
  void dispose() {
    MainShellTabController.instance = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _currentIndex != 0) {
          setState(() => _currentIndex = 0);
        }
      },
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: _tabs),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) => setState(() => _currentIndex = index),
          destinations: [
            for (final d in _destinations)
              NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
                label: d.label,
              ),
          ],
        ),
      ),
    );
  }
}