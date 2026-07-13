import '../../domain/entities/history_entity.dart';

class HistoryModel extends HistoryEntity {
  const HistoryModel({
    super.id,
    required super.query,
    super.wordId,
    required super.searchedAt,
    required super.language,
  });

  factory HistoryModel.fromMap(Map<String, Object?> map) {
    return HistoryModel(
      id: map['id'] as int?,
      query: map['query'] as String,
      wordId: map['word_id'] as int?,
      searchedAt: DateTime.parse(map['searched_at'] as String),
      language: _languageFromString(map['language'] as String),
    );
  }

  Map<String, Object?> toMap({bool includeId = true}) {
    final map = <String, Object?>{
      'query': query,
      'word_id': wordId,
      'searched_at': searchedAt.toIso8601String(),
      'language': _languageToString(language),
    };
    if (includeId && id != null) map['id'] = id;
    return map;
  }

  static SearchLanguage _languageFromString(String value) {
    switch (value) {
      case 'en':
        return SearchLanguage.english;
      case 'bn':
        return SearchLanguage.bangla;
      default:
        return SearchLanguage.auto;
    }
  }

  static String _languageToString(SearchLanguage lang) {
    switch (lang) {
      case SearchLanguage.english:
        return 'en';
      case SearchLanguage.bangla:
        return 'bn';
      case SearchLanguage.auto:
        return 'auto';
    }
  }
}