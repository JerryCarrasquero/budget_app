import 'package:budget_app/core/constants/category_constants.dart';
import 'package:budget_app/core/database/app_database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppDatabase', () {
    test('ensureUncategorizedCategory is idempotent', () async {
      final db = AppDatabase(NativeDatabase.memory());

      final firstId = await db.ensureUncategorizedCategory();
      final secondId = await db.ensureUncategorizedCategory();
      final categories = await db.getAllCategories();
      final uncategorized = categories
          .where((c) => c.name == uncategorizedCategoryName)
          .toList();

      expect(firstId, secondId);
      expect(uncategorized.length, 1);

      await db.close();
    });

    test('deleteCategory does not delete uncategorized category', () async {
      final db = AppDatabase(NativeDatabase.memory());

      final uncategorizedId = await db.ensureUncategorizedCategory();
      final deletedRows = await db.deleteCategory(uncategorizedId);
      final categories = await db.getAllCategories();

      expect(deletedRows, 0);
      expect(categories.any((c) => c.id == uncategorizedId), isTrue);

      await db.close();
    });

    test('insertExpense stores nullable name correctly', () async {
      final db = AppDatabase(NativeDatabase.memory());

      final categoryId = await db.insertCategory(
        CategoriesCompanion.insert(name: 'Food'),
      );

      await db.insertExpense(
        ExpensesCompanion.insert(
          amount: 12.5,
          date: DateTime(2026, 6, 10),
          categoryId: categoryId,
          name: const Value.absent(),
        ),
      );

      final expenses = await db.getAllExpenses();

      expect(expenses.length, 1);
      expect(expenses.first.name, isNull);
      expect(expenses.first.amount, 12.5);

      await db.close();
    });
  });
}
