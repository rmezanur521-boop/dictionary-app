/// Pure domain representation of a dictionary word.
///
/// Contains no persistence or serialization logic — ViewModels and
/// widgets depend on this, never on [WordModel] directly, so the
/// presentation layer stays decoupled from how data is stored/fetched.
class WordEntity {
  final int? id;
  final String english;
  final String bangla;
  final String? pronunciation;
  final String? phonetics;
  final String? partOfSpeech;
  final String? example;
  final List<String> synonyms;
  final List<String> antonyms;
  final String? wordOrigin;
  final int? categoryId;
  final String? categoryName; // populated via JOIN, not persisted directly
  final bool isSynced;
  final DateTime? lastUpdated;
  final int searchCount;

  const WordEntity({
    this.id,
    required this.english,
    required this.bangla,
    this.pronunciation,
    this.phonetics,
    this.partOfSpeech,
    this.example,
    this.synonyms = const [],
    this.antonyms = const [],
    this.wordOrigin,
    this.categoryId,
    this.categoryName,
    this.isSynced = false,
    this.lastUpdated,
    this.searchCount = 0,
  });

  /// True when this word already has enough enrichment data that
  /// we should NOT attempt another API call for it. This single method
  /// is the enforcement point for "never download duplicate data" at
  /// the domain layer (schema-level enforcement is the secondary layer,
  /// see cached_api_data.word_id UNIQUE constraint).
  bool get isEnrichmentComplete {
    return isSynced &&
        (phonetics?.isNotEmpty ?? false) &&
        (example?.isNotEmpty ?? false) &&
        synonyms.isNotEmpty;
  }

  WordEntity copyWith({
    int? id,
    String? english,
    String? bangla,
    String? pronunciation,
    String? phonetics,
    String? partOfSpeech,
    String? example,
    List<String>? synonyms,
    List<String>? antonyms,
    String? wordOrigin,
    int? categoryId,
    String? categoryName,
    bool? isSynced,
    DateTime? lastUpdated,
    int? searchCount,
  }) {
    return WordEntity(
      id: id ?? this.id,
      english: english ?? this.english,
      bangla: bangla ?? this.bangla,
      pronunciation: pronunciation ?? this.pronunciation,
      phonetics: phonetics ?? this.phonetics,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      example: example ?? this.example,
      synonyms: synonyms ?? this.synonyms,
      antonyms: antonyms ?? this.antonyms,
      wordOrigin: wordOrigin ?? this.wordOrigin,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      isSynced: isSynced ?? this.isSynced,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      searchCount: searchCount ?? this.searchCount,
    );
  }

  @override
  bool operator ==(Object other) => other is WordEntity && other.id == id;

  @override
  int get hashCode => id.hashCode;
}