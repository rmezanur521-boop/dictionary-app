import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/enums/load_status.dart';
import '../../../core/routes/app_router.dart';
import '../../providers/category_provider.dart';
import '../../widgets/category_grid_item.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/error_state_widget.dart';
import '../../widgets/loading_widget.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().loadCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: Consumer<CategoryProvider>(
        builder: (context, provider, _) {
          switch (provider.categoriesStatus) {
            case LoadStatus.loading:
              return const LoadingWidget();
            case LoadStatus.error:
              return ErrorStateWidget(
                  message: 'Could not load categories.',
                  onRetry: provider.loadCategories);
            case LoadStatus.empty:
              return const EmptyStateWidget(
                icon: Icons.category_outlined,
                title: 'No categories available',
              );
            case LoadStatus.success:
              return RefreshIndicator(
                onRefresh: provider.loadCategories,
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.3,
                  ),
                  itemCount: provider.categories.length,
                  itemBuilder: (context, index) {
                    final category = provider.categories[index];
                    return CategoryGridItem(
                      category: category,
                      onTap: () =>
                          AppRouter.openCategoryWords(context, category),
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
