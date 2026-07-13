import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/routes/app_router.dart';
import '../../../core/utils/language_detector.dart';
import '../../../domain/entities/history_entity.dart';
import '../../providers/search_provider.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/error_state_widget.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/word_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onResultTap(BuildContext context, String english, int wordId) {
    final provider = context.read<SearchProvider>();
    provider.recordSearch(wordId: wordId);
    _focusNode.unfocus();
    AppRouter.openWordDetails(context, english);
  }

  void _onSubmitted(BuildContext context, String value) {
    if (value.trim().isEmpty) return;
    final provider = context.read<SearchProvider>();
    provider.recordSearch(); // wordId null — resolved once WordDetails loads
    _focusNode.unfocus();
    AppRouter.openWordDetails(context, value.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: _buildSearchField(context),
          ),
          Expanded(child: _buildResultsArea(context)),
        ],
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    final searchProvider = context.watch<SearchProvider>();
    final query = searchProvider.query;
    final detectedLang = query.trim().isEmpty ? null : LanguageDetector.detect(query);

    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      autofocus: false,
      textInputAction: TextInputAction.search,
      onChanged: (value) => context.read<SearchProvider>().onQueryChanged(value),
      onSubmitted: (value) => _onSubmitted(context, value),
      decoration: InputDecoration(
        hintText: 'Type English or বাংলা word...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (detectedLang != null) _buildLanguageBadge(context, detectedLang),
            if (query.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: () {
                  _controller.clear();
                  context.read<SearchProvider>().clearQuery();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageBadge(BuildContext context, SearchLanguage lang) {
    final colorScheme = Theme.of(context).colorScheme;
    final label = lang == SearchLanguage.bangla ? 'বাং' : 'EN';
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }

  Widget _buildResultsArea(BuildContext context) {
    final searchProvider = context.watch<SearchProvider>();

    switch (searchProvider.status) {
      case SearchStatus.idle:
        return const EmptyStateWidget(
          icon: Icons.travel_explore,
          title: 'Start typing to search',
          subtitle: 'Search works fully offline using your local dictionary.',
        );

      case SearchStatus.loading:
        // Deliberately NOT a full-screen spinner — keeps the previous
        // results visible while the debounced query resolves, avoiding
        // an annoying flicker on every keystroke. A subtle top-aligned
        // progress bar communicates "working" without disrupting scroll.
        return Column(
          children: [
            const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: searchProvider.suggestions.isEmpty
                  ? const SizedBox.shrink()
                  : _buildResultsList(context, searchProvider),
            ),
          ],
        );

      case SearchStatus.empty:
        return EmptyStateWidget(
          icon: Icons.search_off,
          title: 'No matches in local dictionary',
          subtitle: 'Press "search" to look it up online if you\'re connected.',
          action: FilledButton.icon(
            onPressed: () => _onSubmitted(context, searchProvider.query),
            icon: const Icon(Icons.travel_explore),
            label: const Text('Search Online'),
          ),
        );

      case SearchStatus.error:
        return ErrorStateWidget(
          message: searchProvider.errorMessage ?? 'Something went wrong.',
          onRetry: () => context.read<SearchProvider>().onQueryChanged(searchProvider.query),
        );

      case SearchStatus.success:
        return _buildResultsList(context, searchProvider);
    }
  }

  Widget _buildResultsList(BuildContext context, SearchProvider searchProvider) {
    final results = searchProvider.suggestions;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final word = results[index];
        return WordCard(
          word: word,
          onTap: () => _onResultTap(context, word.english, word.id!),
        );
      },
    );
  }
}