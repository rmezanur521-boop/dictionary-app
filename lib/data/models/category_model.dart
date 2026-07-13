import '../../domain/entities/category_entity.dart';

class CategoryModel extends CategoryEntity {
  const CategoryModel({super.id, required super.name, super.iconCode, super.wordCount});

  factory CategoryModel.fromMap(Map<String, Object?> map) {
    return CategoryModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      iconCode: map['icon_code'] as String?,
      wordCount: map['word_count'] as int? ?? 0,
    );
  }

  Map<String, Object?> toMap({bool includeId = true}) {
    final map = <String, Object?>{
      'name': name,
      'icon_code': iconCode,
      'word_count': wordCount,
    };
    if (includeId && id != null) map['id'] = id;
    return map;
  }
}