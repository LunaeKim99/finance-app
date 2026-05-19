class Category {
  final String? id;
  final String name;
  final String type;
  final String icon;

  const Category({
    this.id,
    required this.name,
    required this.type,
    this.icon = 'category',
  });

  String get safeId => id ?? '';

  Category copyWith({
    String? id,
    String? name,
    String? type,
    String? icon,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
    );
  }
}
