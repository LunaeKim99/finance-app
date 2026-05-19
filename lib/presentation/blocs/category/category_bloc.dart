import 'package:flutter_bloc/flutter_bloc.dart';
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
      final categories = await _repository.fetchAll();
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
