import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/history_entity.dart';

class HistoryTile extends StatelessWidget {
  const HistoryTile({super.key, required this.entry, required this.onTap});
  final HistoryEntity entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final wasFound = entry.wordId != null;

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: wasFound ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
        child: Icon(
          wasFound ? Icons.check : Icons.search_off,
          size: 18,
          color: wasFound ? colorScheme.onPrimaryContainer : colorScheme.outline,
        ),
      ),
      title: Text(entry.query),
      subtitle: Text(_formatTimestamp(entry.searchedAt)),
      trailing: _LanguageTag(language: entry.language),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    return isToday ? 'Today, ${DateFormat.jm().format(dt)}' : DateFormat('MMM d, y – h:mm a').format(dt);
  }
}

class _LanguageTag extends StatelessWidget {
  const _LanguageTag({required this.language});
  final SearchLanguage language;

  @override
  Widget build(BuildContext context) {
    final label = language == SearchLanguage.bangla ? 'বাং' : 'EN';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}