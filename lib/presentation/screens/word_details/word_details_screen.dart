import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../providers/tts_provider.dart';
import '../../providers/word_details_provider.dart';
import '../../widgets/error_state_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/pos_chip.dart';
import '../../widgets/synonym_antonym_list.dart';

class WordDetailsScreen extends StatefulWidget {
  const WordDetailsScreen({super.key, required this.searchTerm});
  final String searchTerm;

  @override
  State<WordDetailsScreen> createState() => _WordDetailsScreenState();
}

class _WordDetailsScreenState extends State<WordDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WordDetailsProvider>().loadWord(widget.searchTerm);
    });
  }

  @override
  void dispose() {
    // Reset provider state on leaving, so navigating to a *different*
    // word next time doesn't briefly flash the previous word's data.
    context.read<WordDetailsProvider>().reset();
    super.dispose();
  }

  /// Re-runs the lookup for a newly tapped synonym/antonym/recent-word
  /// chip, without pushing a new route (keeps back-stack shallow).
  void _lookupWord(String term) {
    context.read<WordDetailsProvider>().loadWord(term);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WordDetailsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(provider.word?.english ?? widget.searchTerm),
        actions: [
          if (provider.status == DetailsStatus.success) ...[
            IconButton(
              icon: Icon(
                  provider.isFavorite ? Icons.favorite : Icons.favorite_border),
              color: provider.isFavorite
                  ? Theme.of(context).colorScheme.error
                  : null,
              tooltip: 'Toggle favorite',
              onPressed: () =>
                  context.read<WordDetailsProvider>().toggleFavorite(),
            ),
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: 'Share',
              onPressed: () => _shareWord(provider),
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(child: _buildBody(context, provider)),
        ],
      ),
    );
  }

  void _shareWord(WordDetailsProvider provider) {
    final word = provider.word;
    if (word == null) return;
    final text = StringBuffer('${word.english} — ${word.bangla}');
    if (word.example != null && word.example!.isNotEmpty) {
      text.write('\n\n"${word.example}"');
    }
    Share.share(text.toString());
  }

  Widget _buildBody(BuildContext context, WordDetailsProvider provider) {
    switch (provider.status) {
      case DetailsStatus.loading:
        return const LoadingWidget(message: 'Looking up word...');

      case DetailsStatus.notFound:
        return ErrorStateWidget(
          message: provider.errorMessage ?? 'Word not found.',
        );

      case DetailsStatus.error:
        return ErrorStateWidget(
          message: provider.errorMessage ?? 'Something went wrong.',
          onRetry: () => provider.loadWord(widget.searchTerm),
        );

      case DetailsStatus.success:
        return _buildWordDetails(context, provider);
    }
  }

  Widget _buildWordDetails(BuildContext context, WordDetailsProvider provider) {
    final word = provider.word!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── Header: English word + POS + pronunciation + TTS ──────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(word.english, style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (word.partOfSpeech != null &&
                          word.partOfSpeech!.isNotEmpty)
                        PosChip(partOfSpeech: word.partOfSpeech!),
                      if (word.pronunciation != null &&
                          word.pronunciation!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(word.pronunciation!,
                            style: theme.textTheme.bodyMedium),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            _TtsButton(text: word.english),
          ],
        ),

        if (provider.wasEnrichedFromApi) ...[
          const SizedBox(height: 8),
          _SyncedBadge(),
        ],

        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 20),

        // ── Bangla meaning ─────────────────────────────────────────
        Text('Meaning', style: theme.textTheme.titleMedium),
        const SizedBox(height: 6),
        word.bangla.isNotEmpty
            ? Text(
                word.bangla,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: colorScheme.primary,
                  fontSize: 24,
                ),
              )
            : Text(
                'বাংলা অনুবাদ এখনো পাওয়া যায়নি (Bangla translation not available yet)',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.outline,
                  fontStyle: FontStyle.italic,
                ),
              ),
        _BanglaTtsRow(banglaText: word.bangla),

        // ── Example sentence ───────────────────────────────────────
        if (word.example != null && word.example!.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('Example', style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border(
                  left: BorderSide(color: colorScheme.primary, width: 3)),
            ),
            child: Text(
              '"${word.example}"',
              style: theme.textTheme.bodyLarge
                  ?.copyWith(fontStyle: FontStyle.italic),
            ),
          ),
        ],

        // ── Synonyms ────────────────────────────────────────────────
        if (word.synonyms.isNotEmpty) ...[
          const SizedBox(height: 24),
          SynonymAntonymList(
            title: 'Synonyms',
            words: word.synonyms,
            isPositive: true,
            onWordTap: _lookupWord,
          ),
        ],

        // ── Antonyms ────────────────────────────────────────────────
        if (word.antonyms.isNotEmpty) ...[
          const SizedBox(height: 24),
          SynonymAntonymList(
            title: 'Antonyms',
            words: word.antonyms,
            isPositive: false,
            onWordTap: _lookupWord,
          ),
        ],

        // ── Word origin ─────────────────────────────────────────────
        if (word.wordOrigin != null && word.wordOrigin!.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('Origin', style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(word.wordOrigin!, style: theme.textTheme.bodyLarge),
        ],

        // ── Category ────────────────────────────────────────────────
        if (word.categoryName != null && word.categoryName!.isNotEmpty) ...[
          const SizedBox(height: 24),
          Row(
            children: [
              Icon(Icons.label_outline, size: 16, color: colorScheme.outline),
              const SizedBox(width: 6),
              Text('Category: ${word.categoryName}',
                  style: theme.textTheme.bodyMedium),
            ],
          ),
        ],

        const SizedBox(height: 32),
      ],
    );
  }
}

class _TtsButton extends StatelessWidget {
  const _TtsButton({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final ttsProvider = context.watch<TtsProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return IconButton.filledTonal(
      icon: Icon(
          ttsProvider.isSpeaking ? Icons.volume_up : Icons.volume_up_outlined),
      color: ttsProvider.isSpeaking ? colorScheme.primary : null,
      tooltip: 'Pronounce',
      onPressed: () => context.read<TtsProvider>().speakEnglish(text),
    );
  }
}

class _BanglaTtsRow extends StatelessWidget {
  const _BanglaTtsRow({required this.banglaText});
  final String banglaText;

  @override
  Widget build(BuildContext context) {
    final ttsProvider = context.watch<TtsProvider>();
    if (banglaText.isEmpty) return const SizedBox.shrink();

    if (!ttsProvider.isBanglaAvailable) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Tooltip(
          message: 'Bangla voice not installed on this device',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.volume_off_outlined,
                  size: 16, color: Theme.of(context).colorScheme.outline),
              const SizedBox(width: 4),
              Text('Bangla pronunciation unavailable',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontSize: 12)),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: TextButton.icon(
        onPressed: () => context.read<TtsProvider>().speakBangla(banglaText),
        icon: Icon(
            ttsProvider.isSpeaking ? Icons.volume_up : Icons.volume_up_outlined,
            size: 18),
        label: const Text('Listen in Bangla'),
      ),
    );
  }
}

class _SyncedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_done_outlined, size: 14, color: Colors.green),
          const SizedBox(width: 5),
          Text(
            'Updated from online dictionary',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.green.shade700,
                  fontSize: 12,
                ),
          ),
        ],
      ),
    );
  }
}
