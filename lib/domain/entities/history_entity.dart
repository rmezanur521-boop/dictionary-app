enum SearchLanguage { english, bangla, auto }

class HistoryEntity {
  final int? id;
  final String query;
  final int? wordId; // nullable: query may have found nothing
  final DateTime searchedAt;
  final SearchLanguage language;

  const HistoryEntity({
    this.id,
    required this.query,
    this.wordId,
    required this.searchedAt,
    required this.language,
  });
}