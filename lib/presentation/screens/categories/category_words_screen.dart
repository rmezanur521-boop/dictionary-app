import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/enums/load_status.dart';
import '../../../core/routes/app_router.dart';
import '../../../domain/entities/category_entity.dart';
import '../../providers/category_provider.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/error_state_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/word_card.dart';

class CategoryWordsScreen extends StatefulWidget {
  const CategoryWordsScreen({super.key, required this.category});
  final CategoryEntity category;

  @override
  State<CategoryWordsScreen> createState() => _CategoryWordsScreenState();
}

class _CategoryWordsScreenState extends State<CategoryWordsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().loadWordsForCategory(widget.category);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.category.name)),
      body: Consumer<CategoryProvider>(
        builder: (context, provider, _) {
          switch (provider.wordsStatus) {
            case LoadStatus.loading:
              return const LoadingWidget();
            case LoadStatus.error:
              return ErrorStateWidget(
                message: 'Could not load words.',
                onRetry: () => provider.loadWordsForCategory(widget.category),
              );
            case LoadStatus.empty:
              return const EmptyStateWidget(
                icon: Icons.inbox_outlined,
                title: 'No words in this category yet',
              );
            case LoadStatus.success:
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: provider.categoryWords.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final word = provider.categoryWords[index];
                  return WordCard(
                    word: word,
                    onTap: () =>
                        AppRouter.openWordDetails(context, word.english),
                  );
                },
              );
          }
        },
      ),
    );
  }
}
