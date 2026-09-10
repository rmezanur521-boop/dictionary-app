import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/enums/load_status.dart';
import '../../../core/routes/app_router.dart';
import '../../providers/history_provider.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/error_state_widget.dart';
import '../../widgets/history_tile.dart';
import '../../widgets/loading_widget.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryProvider>().loadHistory();
    });
  }

  Future<void> _confirmClearAll(BuildContext context) async {
    final provider = context.read<HistoryProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all history?'),
        content: const Text(
            'This will permanently delete your entire search history. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
    if (confirmed == true) await provider.clearAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search History'),
        actions: [
          Consumer<HistoryProvider>(
            builder: (context, provider, _) {
              if (provider.history.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.delete_sweep_outlined),
                tooltip: 'Clear all',
                onPressed: () => _confirmClearAll(context),
              );
            },
          ),
        ],
      ),
      body: Consumer<HistoryProvider>(
        builder: (context, provider, _) {
          switch (provider.status) {
            case LoadStatus.loading:
              return const LoadingWidget();
            case LoadStatus.error:
              return ErrorStateWidget(
                  message: 'Could not load history.',
                  onRetry: provider.loadHistory);
            case LoadStatus.empty:
              return const EmptyStateWidget(
                icon: Icons.history,
                title: 'No search history yet',
                subtitle: 'Words you search for will appear here.',
              );
            case LoadStatus.success:
              return RefreshIndicator(
                onRefresh: provider.loadHistory,
                child: ListView.builder(
                  itemCount: provider.history.length,
                  itemBuilder: (context, index) {
                    final entry = provider.history[index];
                    return Dismissible(
                      key: ValueKey('history_${entry.id}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Theme.of(context).colorScheme.errorContainer,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete_outline),
                      ),
                      onDismissed: (_) => provider.deleteEntry(entry.id!),
                      child: HistoryTile(
                        entry: entry,
                        onTap: () =>
                            AppRouter.openWordDetails(context, entry.query),
                      ),
                    );
                  },
                ),
              );
          }
        },
      ),
    );
  }
}
