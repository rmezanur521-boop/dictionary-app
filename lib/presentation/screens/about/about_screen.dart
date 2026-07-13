import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/constants/app_constants.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(Icons.menu_book_rounded, size: 40, color: Theme.of(context).colorScheme.onPrimaryContainer),
                ),
                const SizedBox(height: 16),
                Text(AppConstants.appName, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    final version = snapshot.data != null
                        ? 'v${snapshot.data!.version} (build ${snapshot.data!.buildNumber})'
                        : '';
                    return Text(version, style: Theme.of(context).textTheme.bodyMedium);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'An offline-first English–Bangla dictionary. Search over 50,000 words '
            'instantly without an internet connection. When online, the app '
            'automatically enriches word entries with pronunciation, examples, '
            'synonyms, and antonyms from an online dictionary source — and saves '
            'that data locally so it works offline forever after.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          const _InfoTile(icon: Icons.architecture, title: 'Architecture', subtitle: 'Clean Architecture • MVVM • Repository Pattern'),
          const _InfoTile(icon: Icons.storage, title: 'Local Storage', subtitle: 'SQLite (sqflite) — 50,000+ preloaded words'),
          const _InfoTile(icon: Icons.cloud_sync_outlined, title: 'Online Enrichment', subtitle: 'Free Dictionary API (dictionaryapi.dev)'),
          const _InfoTile(icon: Icons.code, title: 'Built With', subtitle: 'Flutter & Dart'),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Developed as a Final Year Project',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}