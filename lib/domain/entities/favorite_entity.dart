class FavoriteEntity {
  final int? id;
  final int wordId;
  final DateTime addedAt;

  const FavoriteEntity({
    this.id,
    required this.wordId,
    required this.addedAt,
  });
}