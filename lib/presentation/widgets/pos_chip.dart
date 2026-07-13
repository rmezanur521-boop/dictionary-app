import 'package:flutter/material.dart';

/// Small chip displaying part-of-speech (noun, verb, adjective...).
/// Reused on WordCard and WordDetails.
class PosChip extends StatelessWidget {
  const PosChip({super.key, required this.partOfSpeech});
  final String partOfSpeech;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        partOfSpeech,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: colorScheme.onTertiaryContainer,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}