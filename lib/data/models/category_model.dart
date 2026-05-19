import 'package:pocketbase/pocketbase.dart';

class CategoryModel {
  final String? id;
  final String name;
  final String type;
  final String icon;
  final String? user;

  const CategoryModel({
    this.id,
    required this.name,
    required this.type,
    this.icon = 'category',
    this.user,
  });

  String get safeId => id ?? '';

  factory CategoryModel.fromRecord(RecordModel record) {
    return CategoryModel(
      id: record.id,
      name: record.data['name'] as String,
      type: record.data['type'] as String,
      icon: (record.data['icon'] as String?) ?? 'category',
      user: record.data['user'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'icon': icon,
      if (user != null) 'user': user,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as String?,
      name: map['name'] as String,
      type: map['type'] as String,
      icon: (map['icon'] as String?) ?? 'category',
      user: map['user'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'icon': icon,
      'user': user,
    };
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    String? type,
    String? icon,
    String? user,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      user: user ?? this.user,
    );
  }
}
