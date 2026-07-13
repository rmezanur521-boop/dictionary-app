import 'package:flutter/material.dart';

/// Displays a wrap of tappable chips for synonyms or antonyms.
/// Tapping a chip re-searches for that word — a genuinely useful
/// "dictionary browsing" affordance, not just a static list.
class SynonymAntonymList extends StatelessWidget {
  const SynonymAntonymList({
    super.key,
    required this.title,
    required this.words,
    required this.onWordTap,
    required this.isPositive,
  });

  final String title;
  final List<String> words;
  final void Function(String word) onWordTap;
  final bool isPositive; // true = synonyms (primary color), false = antonyms (error/outline)

  @override
  Widget build(BuildContext context) {
    if (words.isEmpty) return const SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;
    final chipColor = isPositive ? colorScheme.primaryContainer : colorScheme.errorContainer;
    final textColor = isPositive ? colorScheme.onPrimaryContainer : colorScheme.onErrorContainer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final word in words)
              ActionChip(
                label: Text(word),
                backgroundColor: chipColor,
                labelStyle: TextStyle(color: textColor, fontSize: 13),
                side: BorderSide.none,
                onPressed: () => onWordTap(word),
              ),
          ],
        ),
      ],
    );
  }
}