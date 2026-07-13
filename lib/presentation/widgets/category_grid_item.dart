import 'package:flutter/material.dart';

import '../../domain/entities/category_entity.dart';

class CategoryGridItem extends StatelessWidget {
  const CategoryGridItem({super.key, required this.category, required this.onTap});
  final CategoryEntity category;
  final VoidCallback onTap;

  static const Map<String, IconData> _iconMap = {
    'science': Icons.science_outlined,
    'business': Icons.business_center_outlined,
    'nature': Icons.eco_outlined,
    'food': Icons.restaurant_outlined,
    'technology': Icons.memory_outlined,
    'travel': Icons.flight_outlined,
    'health': Icons.favorite_border,
    'sports': Icons.sports_soccer_outlined,
    'art': Icons.palette_outlined,
    'education': Icons.school_outlined,
  };

  IconData _resolveIcon() {
    final key = category.iconCode?.toLowerCase();
    return _iconMap[key] ?? Icons.category_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_resolveIcon(), size: 28, color: colorScheme.primary),
              const SizedBox(height: 12),
              Text(category.name, style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text('${category.wordCount} words', style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}