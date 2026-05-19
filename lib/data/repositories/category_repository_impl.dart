import '../../data/models/category_model.dart';
import '../../data/datasources/smart_db_helper.dart';
import '../../data/datasources/pb_helper.dart';
import '../../data/datasources/local/sqlite_helper.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final SmartDbHelper _db;

  CategoryRepositoryImpl()
      : _db = SmartDbHelper(remote: PbHelper(), local: SqliteHelper());

  @override
  Future<List<Category>> fetchAll() async {
    final models = await _db.fetchAllCategories();
    return models.map((m) => Category(
      id: m.id,
      name: m.name,
      type: m.type,
      icon: m.icon,
    )).toList();
  }

  @override
  Future<Category> create(Category category) async {
    final model = CategoryModel(
      name: category.name,
      type: category.type,
      icon: category.icon,
    );
    final result = await _db.createCategory(model);
    return Category(
      id: result.id,
      name: result.name,
      type: result.type,
      icon: result.icon,
    );
  }

  @override
  Future<void> delete(String id) async {
    await _db.deleteCategory(id);
  }

  @override
  Future<Category> update(String id, Category category) async {
    final model = CategoryModel(
      name: category.name,
      type: category.type,
      icon: category.icon,
    );
    final result = await _db.updateCategory(id, model);
    return Category(
      id: result.id,
      name: result.name,
      type: result.type,
      icon: result.icon,
    );
  }
}
