import 'package:budget_app/core/database/app_database.dart';
import 'package:budget_app/feature/categories/domain/exceptions/duplicate_category_name_exception.dart';
import 'package:drift/drift.dart';

class CategoryDataSource {
  final AppDatabase _database;

  CategoryDataSource(this._database);

  Stream<List<Category>> watchAllCategories() {
    return _database.watchAllCategories();
  }

  Future<void> addCategory({
    required String name,
    required int color,
    required int icon,
  }) async {
    await _database.transaction(() async {
      final existing =
          await (_database.select(_database.categories)
                ..where((tbl) => tbl.name.lower().equals(name.toLowerCase()))
                ..limit(2))
              .get();

      if (existing.isNotEmpty) {
        throw DuplicateCategoryNameException(name);
      }

      await _database.insertCategory(
        CategoriesCompanion(
          name: Value(name),
          color: Value(color),
          icon: Value(icon),
        ),
      );
    });
  }

  Future<void> deleteCategory(int id) async {
    await _database.deleteCategory(id);
  }
}
