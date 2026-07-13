class CachedApiModel {
  final int? id;
  final int wordId;
  final String rawJson;
  final String source;
  final DateTime fetchedAt;

  const CachedApiModel({
    this.id,
    required this.wordId,
    required this.rawJson,
    this.source = 'dictionaryapi.dev',
    required this.fetchedAt,
  });

  factory CachedApiModel.fromMap(Map<String, Object?> map) {
    return CachedApiModel(
      id: map['id'] as int?,
      wordId: map['word_id'] as int,
      rawJson: map['raw_json'] as String,
      source: map['source'] as String? ?? 'dictionaryapi.dev',
      fetchedAt: DateTime.parse(map['fetched_at'] as String),
    );
  }

  Map<String, Object?> toMap({bool includeId = true}) {
    final map = <String, Object?>{
      'word_id': wordId,
      'raw_json': rawJson,
      'source': source,
      'fetched_at': fetchedAt.toIso8601String(),
    };
    if (includeId && id != null) map['id'] = id;
    return map;
  }
}