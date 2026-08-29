class CategoryModel {
  final int? id;
  final String name;
  final DateTime? createdAt;

  const CategoryModel({
    this.id,
    required this.name,
    this.createdAt,
  });

  factory CategoryModel.fromMap(Map<String, Object?> map) {
    return CategoryModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
    };
  }

  CategoryModel copyWith({int? id, String? name}) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt,
    );
  }
}
