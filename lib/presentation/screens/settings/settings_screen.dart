import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/routes/app_router.dart';
import '../../providers/settings_provider.dart';
import '../../providers/sync_status_provider.dart';
import '../../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsProvider>().loadSettingsInfo();
    });
  }

  Future<void> _confirmClearHistory(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear search history?'),
        content: const Text('This permanently deletes all recorded searches. Favorites and dictionary data are not affected.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<SettingsProvider>().clearSearchHistory();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Search history cleared')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return ListView(
            children: [
              _SectionHeader('Appearance'),
              _buildThemeSelector(context),
              const Divider(),

              _SectionHeader('Data & Sync'),
              _buildSyncStatusTile(context),
              ListTile(
                leading: const Icon(Icons.storage_outlined),
                title: const Text('Database Information'),
                subtitle: settings.isLoading
                    ? const Text('Loading...')
                    : Text('${settings.totalWords} words • ${settings.dbSizeFormatted}'),
                trailing: settings.isLoading
                    ? null
                    : Text('${settings.syncPercentage.toStringAsFixed(1)}% enriched',
                        style: Theme.of(context).textTheme.bodyMedium),
              ),
              ListTile(
                leading: const Icon(Icons.delete_sweep_outlined),
                title: const Text('Clear Search History'),
                onTap: () => _confirmClearHistory(context),
              ),
              const Divider(),

              _SectionHeader('About'),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('About This App'),
                onTap: () => AppRouter.openAbout(context),
              ),
              ListTile(
                leading: const Icon(Icons.system_update_alt_outlined),
                title: const Text('App Version'),
                trailing: Text(settings.isLoading ? '...' : settings.appVersion),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SegmentedButton<ThemeMode>(
        segments: const [
          ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_outlined), label: Text('Light')),
          ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_outlined), label: Text('Dark')),
          ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto_outlined), label: Text('System')),
        ],
        selected: {themeProvider.themeMode},
        onSelectionChanged: (selection) => context.read<ThemeProvider>().setThemeMode(selection.first),
      ),
    );
  }

  Widget _buildSyncStatusTile(BuildContext context) {
    final syncStatus = context.watch<SyncStatusProvider>();
    final settings = context.watch<SettingsProvider>();

    String subtitle;
    IconData icon;
    Color? color;

    switch (syncStatus.event) {
      case SyncEvent.syncing:
        subtitle = 'Syncing "${syncStatus.lastUpdate.wordBeingSynced}"...';
        icon = Icons.sync;
        color = Colors.blue;
      case SyncEvent.success:
        subtitle = 'Last synced: "${syncStatus.lastUpdate.wordBeingSynced}"';
        icon = Icons.cloud_done_outlined;
        color = Colors.green;
      case SyncEvent.failed:
        subtitle = 'Sync failed: ${syncStatus.lastUpdate.message ?? "unknown error"}';
        icon = Icons.cloud_off_outlined;
        color = Colors.red;
      case SyncEvent.idle:
        subtitle = settings.lastSyncAt != null
            ? 'Last sync: ${settings.lastSyncAt}'
            : 'No sync activity yet';
        icon = Icons.cloud_outlined;
        color = null;
    }

    return ListTile(
      leading: Icon(icon, color: color),
      title: const Text('API Sync Status'),
      subtitle: Text(subtitle),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}