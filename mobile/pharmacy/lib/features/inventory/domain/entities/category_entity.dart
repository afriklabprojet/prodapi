/// Entité catégorie de la couche domaine.
class CategoryEntity {
  final int id;
  final String name;
  final String? slug;
  final String? description;

  const CategoryEntity({
    required this.id,
    required this.name,
    this.slug,
    this.description,
  });

  CategoryEntity copyWith({
    int? id,
    String? name,
    String? slug,
    String? description,
  }) {
    return CategoryEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      description: description ?? this.description,
    );
  }

  @override
  String toString() => 'CategoryEntity(id: $id, name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
