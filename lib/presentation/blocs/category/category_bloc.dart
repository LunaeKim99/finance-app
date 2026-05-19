import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/default_categories.dart';
import '../../../domain/entities/category.dart' as entities;
import '../../../domain/repositories/category_repository.dart';
import 'category_event.dart';
import 'category_state.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final CategoryRepository _repository;

  CategoryBloc({required CategoryRepository repository})
      : _repository = repository,
        super(const CategoryInitial()) {
    on<CategoryLoadRequested>(_onLoad);
    on<CategoryCreated>(_onCreate);
    on<CategoryUpdated>(_onUpdate);
    on<CategoryDeleted>(_onDelete);
  }

  Future<void> _onLoad(CategoryLoadRequested event, Emitter<CategoryState> emit) async {
    emit(const CategoryLoading());
    try {
      var categories = await _repository.fetchAll();
      if (categories.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final seeded = prefs.getBool('categories_seeded_v1') ?? false;
        if (!seeded) {
          for (final entry in DefaultCategories.list) {
            await _repository.create(entities.Category(
              name: entry.name,
              type: entry.type,
              icon: entry.icon,
            ));
          }
          await prefs.setBool('categories_seeded_v1', true);
          categories = await _repository.fetchAll();
          debugPrint('[CategoryBloc] Seeded ${DefaultCategories.list.length} default categories');
        }
      }
      emit(CategoryLoaded(categories: categories));
    } catch (e) {
      emit(CategoryError(message: e.toString()));
    }
  }

  Future<void> _onCreate(CategoryCreated event, Emitter<CategoryState> emit) async {
    try {
      await _repository.create(event.category);
      final categories = await _repository.fetchAll();
      emit(CategoryLoaded(categories: categories));
    } catch (e) {
      emit(CategoryError(message: e.toString()));
    }
  }

  Future<void> _onUpdate(CategoryUpdated event, Emitter<CategoryState> emit) async {
    try {
      await _repository.update(event.id, event.category);
      final categories = await _repository.fetchAll();
      emit(CategoryLoaded(categories: categories));
    } catch (e) {
      emit(CategoryError(message: e.toString()));
    }
  }

  Future<void> _onDelete(CategoryDeleted event, Emitter<CategoryState> emit) async {
    try {
      await _repository.delete(event.id);
      final categories = await _repository.fetchAll();
      emit(CategoryLoaded(categories: categories));
    } catch (e) {
      emit(CategoryError(message: e.toString()));
    }
  }
}
