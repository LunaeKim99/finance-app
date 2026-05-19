import '../../domain/entities/category.dart';

abstract class CategoryRepository {
  Future<List<Category>> fetchAll();
  Future<Category> create(Category category);
  Future<void> delete(String id);
  Future<Category> update(String id, Category category);
}
