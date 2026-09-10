import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/enums/load_status.dart';
import '../../../core/routes/app_router.dart';
import '../../providers/daily_word_provider.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/error_state_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/pos_chip.dart';

class DailyWordScreen extends StatefulWidget {
  const DailyWordScreen({super.key});

  @override
  State<DailyWordScreen> createState() => _DailyWordScreenState();
}

class _DailyWordScreenState extends State<DailyWordScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DailyWordProvider>().loadDailyWord();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Word of the Day')),
      body: Consumer<DailyWordProvider>(
        builder: (context, provider, _) {
          switch (provider.status) {
            case LoadStatus.loading:
              return const LoadingWidget();
            case LoadStatus.error:
              return ErrorStateWidget(
                  message: 'Could not load today\'s word.',
                  onRetry: provider.loadDailyWord);
            case LoadStatus.empty:
              return const EmptyStateWidget(
                  icon: Icons.auto_awesome, title: 'No word available yet');
            case LoadStatus.success:
              final word = provider.dailyWord!;
              final theme = Theme.of(context);
              final colorScheme = theme.colorScheme;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DateFormat('EEEE, MMMM d, y').format(DateTime.now()),
                        style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.primaryContainer,
                            colorScheme.tertiaryContainer
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(word.english,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                  color: colorScheme.onPrimaryContainer)),
                          const SizedBox(height: 6),
                          if (word.partOfSpeech != null)
                            PosChip(partOfSpeech: word.partOfSpeech!),
                          const SizedBox(height: 12),
                          Text(
                            word.bangla.isNotEmpty
                                ? word.bangla
                                : 'বাংলা অনুবাদ পাওয়া যায়নি',
                            style: theme.textTheme.titleLarge?.copyWith(
                                color: colorScheme.onPrimaryContainer),
                          ),
                          if (word.example != null &&
                              word.example!.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text('"${word.example}"',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.onPrimaryContainer
                                        .withValues(alpha: 0.85),
                                    fontStyle: FontStyle.italic)),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () =>
                          AppRouter.openWordDetails(context, word.english),
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('View Full Details'),
                    ),
                  ],
                ),
              );
          }
        },
      ),
    );
  }
}
