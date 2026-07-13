import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/routes/app_router.dart';
import '../../../domain/entities/word_entity.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/daily_word_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/history_provider.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/section_title.dart';
import '../../widgets/word_card.dart';
import '../search/search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load all Home-screen data sources once on first build. Using
    // addPostFrameCallback avoids calling notifyListeners() during
    // the build phase (a common Provider pitfall).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DailyWordProvider>().loadDailyWord();
      context.read<FavoritesProvider>().loadFavorites();
      context.read<HistoryProvider>().loadHistory();
    });
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      context.read<DailyWordProvider>().loadDailyWord(),
      context.read<FavoritesProvider>().loadFavorites(),
      context.read<HistoryProvider>().loadHistory(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('অভিধান'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Search History',
            onPressed: () => AppRouter.openHistory(context),
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  _buildSearchEntryCard(context),
                  const SizedBox(height: 24),
                  _buildDailyWordSection(context),
                  const SizedBox(height: 24),
                  _buildRecentSearchesSection(context),
                  const SizedBox(height: 24),
                  _buildFavoritesSection(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Tapping this doesn't navigate to a route — it switches the
  /// bottom-nav tab to Search (index 1), matching the shell's
  /// IndexedStack pattern from Step 12, so the user lands on a fully
  /// interactive search bar rather than a dead-end preview.
  Widget _buildSearchEntryCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: () => _switchToSearchTab(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Text(
              'Search English or বাংলা word...',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _switchToSearchTab(BuildContext context) {
    // MainShell owns tab index state; the cleanest way to hand off
    // without tightly coupling HomeScreen to MainShell internals is
    // a dedicated inherited notifier — for this project's scope, we
    // instead expose a simple static callback hook set by MainShell.
    MainShellTabController.instance?.switchToTab(1);
  }

  Widget _buildDailyWordSection(BuildContext context) {
    final dailyProvider = context.watch<DailyWordProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Word of the Day'),
        switch (dailyProvider.status) {
          LoadStatus.loading => const SizedBox(height: 100, child: LoadingWidget()),
          LoadStatus.error => const SizedBox(
              height: 80,
              child: Center(child: Text('Could not load daily word')),
            ),
          LoadStatus.empty => const SizedBox(
              height: 80,
              child: Center(child: Text('No word available yet')),
            ),
          LoadStatus.success => _DailyWordCard(word: dailyProvider.dailyWord!),
        },
      ],
    );
  }

  Widget _buildRecentSearchesSection(BuildContext context) {
    final historyProvider = context.watch<HistoryProvider>();
    final recent = historyProvider.history.take(5).toList();

    if (historyProvider.status == LoadStatus.loading) {
      return const SizedBox.shrink();
    }
    if (recent.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          title: 'Recent Searches',
          actionLabel: 'See all',
          onActionTap: () => AppRouter.openHistory(context),
        ),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: recent.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final entry = recent[index];
              return ActionChip(
                label: Text(entry.query),
                onPressed: () => AppRouter.openWordDetails(context, entry.query),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFavoritesSection(BuildContext context) {
    final favoritesProvider = context.watch<FavoritesProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          title: 'Favorite Words',
          actionLabel: favoritesProvider.favorites.isNotEmpty ? 'See all' : null,
          onActionTap: () => MainShellTabController.instance?.switchToTab(2),
        ),
        switch (favoritesProvider.status) {
          LoadStatus.loading => const SizedBox(height: 80, child: LoadingWidget()),
          LoadStatus.error => const SizedBox.shrink(),
          LoadStatus.empty => const EmptyStateWidget(
              icon: Icons.favorite_border,
              title: 'No favorites yet',
              subtitle: 'Tap the heart icon on any word to save it here.',
            ),
          LoadStatus.success => Column(
              children: [
                for (final word in favoritesProvider.favorites.take(3))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: WordCard(
                      word: word,
                      onTap: () => AppRouter.openWordDetails(context, word.english),
                    ),
                  ),
              ],
            ),
        },
      ],
    );
  }
}

class _DailyWordCard extends StatelessWidget {
  const _DailyWordCard({required this.word});
  final WordEntity word;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primaryContainer, colorScheme.tertiaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => AppRouter.openWordDetails(context, word.english),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, size: 16, color: colorScheme.onPrimaryContainer),
                const SizedBox(width: 6),
                Text(
                  "TODAY'S WORD",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              word.english,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              word.bangla,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
            ),
            if (word.example != null && word.example!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '"${word.example}"',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer.withValues(alpha: 0.85),
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}