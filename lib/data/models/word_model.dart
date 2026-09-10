import '../../domain/entities/word_entity.dart';

class WordModel extends WordEntity {
  const WordModel({
    super.id,
    required super.english,
    required super.bangla,
    super.pronunciation,
    super.phonetics,
    super.partOfSpeech,
    super.example,
    super.synonyms,
    super.antonyms,
    super.wordOrigin,
    super.categoryId,
    super.categoryName,
    super.isSynced,
    super.lastUpdated,
    super.searchCount,
  });

  factory WordModel.fromMap(Map<String, Object?> map) {
    return WordModel(
      id: map['id'] as int?,
      english: map['english'] as String,
      bangla: map['bangla'] as String,
      pronunciation: map['pronunciation'] as String?,
      phonetics: map['phonetics'] as String?,
      partOfSpeech: map['part_of_speech'] as String?,
      example: map['example'] as String?,
      synonyms: _splitPipeDelimited(map['synonyms'] as String?),
      antonyms: _splitPipeDelimited(map['antonyms'] as String?),
      wordOrigin: map['word_origin'] as String?,
      categoryId: map['category_id'] as int?,
      categoryName: map['category_name'] as String?, // present only if joined
      isSynced: (map['is_synced'] as int? ?? 0) == 1,
      lastUpdated: map['last_updated'] != null
          ? DateTime.tryParse(map['last_updated'] as String)
          : null,
      searchCount: map['search_count'] as int? ?? 0,
    );
  }

  /// Converts to a SQLite-ready map. Excludes [id] when null so
  /// AUTOINCREMENT works correctly on insert.
  Map<String, Object?> toMap({bool includeId = true}) {
    final map = <String, Object?>{
      'english': english,
      'bangla': bangla,
      'pronunciation': pronunciation,
      'phonetics': phonetics,
      'part_of_speech': partOfSpeech,
      'example': example,
      'synonyms': _joinPipeDelimited(synonyms),
      'antonyms': _joinPipeDelimited(antonyms),
      'word_origin': wordOrigin,
      'category_id': categoryId,
      'is_synced': isSynced ? 1 : 0,
      'last_updated': lastUpdated?.toIso8601String(),
      'search_count': searchCount,
    };
    if (includeId && id != null) map['id'] = id;
    return map;
  }

  /// Parses a Free Dictionary API (dictionaryapi.dev) response fragment
  /// and merges it onto an existing local word, producing enrichment
  /// fields only — english/bangla always come from local data, never
  /// overwritten by the API (API has no Bangla knowledge at all).
  ///
  /// Expected shape (per dictionaryapi.dev):
  /// [{
  ///   "word": "hello",
  ///   "phonetic": "/həˈloʊ/",
  ///   "phonetics": [{ "text": "...", "audio": "..." }],
  ///   "meanings": [{
  ///     "partOfSpeech": "exclamation",
  ///     "definitions": [{ "definition": "...", "example": "...",
  ///                        "synonyms": [...], "antonyms": [...] }]
  ///   }],
  ///   "origin": "..." // deprecated by API but handled if present
  /// }]
  static WordModel mergeApiEnrichment({
    required WordModel localWord,
    required Map<String, dynamic> apiEntry,
  }) {
    final String? phonetic = apiEntry['phonetic'] as String?;

    String? example;
    String? partOfSpeech;
    final List<String> synonyms = [];
    final List<String> antonyms = [];

    final meanings = apiEntry['meanings'] as List<dynamic>? ?? [];
    for (final meaning in meanings) {
      final pos = meaning['partOfSpeech'] as String?;
      partOfSpeech ??= pos; // take the first meaning's POS as primary

      final definitions = meaning['definitions'] as List<dynamic>? ?? [];
      for (final def in definitions) {
        example ??= def['example'] as String?;

        final defSynonyms =
            (def['synonyms'] as List<dynamic>? ?? []).map((e) => e.toString());
        synonyms.addAll(defSynonyms);

        final defAntonyms =
            (def['antonyms'] as List<dynamic>? ?? []).map((e) => e.toString());
        antonyms.addAll(defAntonyms);
      }

      // Meaning-level synonyms/antonyms (API also provides these at
      // the meaning level, not just definition level)
      synonyms.addAll(
        (meaning['synonyms'] as List<dynamic>? ?? []).map((e) => e.toString()),
      );
      antonyms.addAll(
        (meaning['antonyms'] as List<dynamic>? ?? []).map((e) => e.toString()),
      );
    }

    return localWord.copyWithModel(
      pronunciation: localWord.pronunciation ?? phonetic,
      phonetics: phonetic ?? localWord.phonetics,
      partOfSpeech: partOfSpeech ?? localWord.partOfSpeech,
      example: example ?? localWord.example,
      synonyms: synonyms.isNotEmpty
          ? {...localWord.synonyms, ...synonyms}.toList()
          : localWord.synonyms,
      antonyms: antonyms.isNotEmpty
          ? {...localWord.antonyms, ...antonyms}.toList()
          : localWord.antonyms,
      isSynced: true,
      lastUpdated: DateTime.now(),
    );
  }

  WordModel copyWithModel({
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
    return WordModel(
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

  static List<String> _splitPipeDelimited(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];
    return raw
        .split('|')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  static String? _joinPipeDelimited(List<String> values) {
    if (values.isEmpty) return null;
    return values.join('|');
  }
}
