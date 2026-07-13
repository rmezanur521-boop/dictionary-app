import '../../domain/entities/favorite_entity.dart';

class FavoriteModel extends FavoriteEntity {
  const FavoriteModel({super.id, required super.wordId, required super.addedAt});

  factory FavoriteModel.fromMap(Map<String, Object?> map) {
    return FavoriteModel(
      id: map['id'] as int?,
      wordId: map['word_id'] as int,
      addedAt: DateTime.parse(map['added_at'] as String),
    );
  }

  Map<String, Object?> toMap({bool includeId = true}) {
    final map = <String, Object?>{
      'word_id': wordId,
      'added_at': addedAt.toIso8601String(),
    };
    if (includeId && id != null) map['id'] = id;
    return map;
  }
}