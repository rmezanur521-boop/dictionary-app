class CategoryEntity {
  final int? id;
  final String name;
  final String? iconCode;
  final int wordCount;

  const CategoryEntity({
    this.id,
    required this.name,
    this.iconCode,
    this.wordCount = 0,
  });
}