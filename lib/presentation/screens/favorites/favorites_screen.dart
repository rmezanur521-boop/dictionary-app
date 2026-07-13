```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/routes/app_router.dart';
import '../../../domain/entities/word_entity.dart';
import '../../providers/favorites_provider.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/error_state_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/word_card.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FavoritesProvider>().loadFavorites();
    });
  }

  Future<void> _removeWithUndo(
    BuildContext context,
    WordEntity word,
  ) async {
    final provider = context.read<FavoritesProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final removed = await provider.removeFavorite(word.id!);

    if (removed == null) return;

    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        content: Text('Removed "${removed.english}" from favorites'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => provider.restoreFavorite(removed),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite Words'),
      ),
      body: Consumer<FavoritesProvider>(
        builder: (context, provider, _) {
          return RefreshIndicator(
            onRefresh: provider.loadFavorites,
            child: _buildBody(context, provider),
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    FavoritesProvider provider,
  ) {
    switch (provider.status) {
      case LoadStatus.loading:
        return const LoadingWidget();

      case LoadStatus.error:
        return ErrorStateWidget(
          message: 'Could not load favorites.',
          onRetry: provider.loadFavorites,
        );

      case LoadStatus.empty:
        return ListView(
          children: const [
            SizedBox(height: 100),
            EmptyStateWidget(
              icon: Icons.favorite_border,
              title: 'No favorites yet',
              subtitle:
                  'Tap the heart icon on any word\'s details page to save it here.',
            ),
          ],
        );

      case LoadStatus.success:
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: provider.favorites.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final word = provider.favorites[index];

            return Dismissible(
              key: ValueKey('favorite_${word.id}'),
              direction: DismissDirection.endToStart,
              background: _buildDismissBackground(context),
              onDismissed: (_) => _removeWithUndo(context, word),
              child: WordCard(
                word: word,
                onTap: () => AppRouter.openWordDetails(
                  context,
                  word.english,
                ),
                trailing: const Icon(
                  Icons.favorite,
                  color: Colors.redAccent,
                  size: 20,
                ),
              ),
            );
          },
        );
    }
  }

  Widget _buildDismissBackground(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        Icons.delete_outline,
        color: colorScheme.onErrorContainer,
      ),
    );
  }
}
```
