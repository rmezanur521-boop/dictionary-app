import 'package:flutter/material.dart';

import '../../domain/entities/word_entity.dart';
import 'pos_chip.dart';

/// The single most reused widget in the app — displays a word summary
/// (english, bangla, part of speech, sync indicator) on Home, Search,
/// Favorites, and Category screens. Kept dumb/stateless: purely
/// renders a WordEntity + callbacks, no provider access.
class WordCard extends StatelessWidget {
  const WordCard({
    super.key,
    required this.word,
    required this.onTap,
    this.trailing,
  });

  final WordEntity word;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            word.english,
                            style: theme.textTheme.titleMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (word.partOfSpeech != null && word.partOfSpeech!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          PosChip(partOfSpeech: word.partOfSpeech!),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      word.bangla.isNotEmpty ? word.bangla : 'অনুবাদ পাওয়া যায়নি',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: word.bangla.isNotEmpty
                            ? colorScheme.primary
                            : colorScheme.outline,
                        fontStyle: word.bangla.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                      ),
                    ),
                    if (word.pronunciation != null && word.pronunciation!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        word.pronunciation!,
                        style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!
              else Icon(Icons.chevron_right, color: colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}