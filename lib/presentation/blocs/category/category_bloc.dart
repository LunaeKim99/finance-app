import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/default_categories.dart';
import '../../../domain/entities/category.dart' as entities;
import 'category_event.dart';
import 'category_state.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  CategoryBloc() : super(const CategoryInitial()) {
    on<CategoryLoadRequested>(_onLoad);
  }

  Future<void> _onLoad(CategoryLoadRequested event, Emitter<CategoryState> emit) async {
    emit(const CategoryLoading());
    try {
      final categories = DefaultCategories.list.map((entry) => entities.Category(
        name: entry.name,
        type: entry.type,
        icon: entry.icon,
      )).toList();
      emit(CategoryLoaded(categories: categories));
    } catch (e) {
      emit(CategoryError(message: e.toString()));
    }
  }
}
