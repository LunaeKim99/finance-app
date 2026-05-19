import 'package:equatable/equatable.dart';
import '../../../domain/entities/category.dart';

abstract class CategoryEvent extends Equatable {
  const CategoryEvent();

  @override
  List<Object?> get props => [];
}

class CategoryLoadRequested extends CategoryEvent {
  const CategoryLoadRequested();
}

class CategoryCreated extends CategoryEvent {
  final Category category;

  const CategoryCreated({required this.category});

  @override
  List<Object?> get props => [category];
}

class CategoryUpdated extends CategoryEvent {
  final String id;
  final Category category;

  const CategoryUpdated({required this.id, required this.category});

  @override
  List<Object?> get props => [id, category];
}

class CategoryDeleted extends CategoryEvent {
  final String id;

  const CategoryDeleted({required this.id});

  @override
  List<Object?> get props => [id];
}
