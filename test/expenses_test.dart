import 'package:budget_app/core/constants/category_constants.dart';
import 'package:budget_app/core/database/app_database.dart';
import 'package:budget_app/feature/home/data/expense_data_source.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Expenses', () {
    test('insert and get expenses', () async {
      final db = AppDatabase(NativeDatabase.memory());

      final categoryId = await db.insertCategory(
        CategoriesCompanion.insert(name: 'Food'),
      );

      await db.insertExpense(
        ExpensesCompanion.insert(
          amount: 50,
          date: DateTime(2026, 6, 1),
          categoryId: categoryId,
          name: const Value('Lunch'),
        ),
      );

      final expenses = await db.getAllExpenses();

      expect(expenses.length, 1);
      expect(expenses.first.name, 'Lunch');
      expect(expenses.first.amount, 50);
      expect(expenses.first.categoryId, categoryId);

      await db.close();
    });

    test('monthly joined and grouped queries return expected data', () async {
      final db = AppDatabase(NativeDatabase.memory());

      final foodId = await db.insertCategory(
        CategoriesCompanion.insert(name: 'Food'),
      );
      final transportId = await db.insertCategory(
        CategoriesCompanion.insert(name: 'Transport'),
      );

      await db.insertExpense(
        ExpensesCompanion.insert(
          amount: 80,
          date: DateTime(2026, 6, 3),
          categoryId: foodId,
          name: const Value('Groceries'),
        ),
      );
      await db.insertExpense(
        ExpensesCompanion.insert(
          amount: 20,
          date: DateTime(2026, 6, 6),
          categoryId: transportId,
          name: const Value('Bus'),
        ),
      );
      await db.insertExpense(
        ExpensesCompanion.insert(
          amount: 10,
          date: DateTime(2026, 7, 1),
          categoryId: foodId,
          name: const Value('Snack'),
        ),
      );

      final joined = await db.getExpensesWithCategoryByMonth(2026, 6);
      final totals = await db.getCategoryTotalsByMonth(2026, 6);

      expect(joined.length, 2);
      expect(joined.any((row) => row.category.name == 'Food'), isTrue);
      expect(joined.any((row) => row.category.name == 'Transport'), isTrue);

      final foodTotal = totals.firstWhere((row) => row.category.name == 'Food');
      final transportTotal = totals.firstWhere((row) => row.category.name == 'Transport');

      expect(foodTotal.total, 80);
      expect(transportTotal.total, 20);

      await db.close();
    });

    test('deleting category reassigns expenses to uncategorized', () async {
      final db = AppDatabase(NativeDatabase.memory());

      final travelId = await db.insertCategory(
        CategoriesCompanion.insert(name: 'Travel'),
      );

      await db.insertExpense(
        ExpensesCompanion.insert(
          amount: 120,
          date: DateTime(2026, 6, 10),
          categoryId: travelId,
          name: const Value('Taxi'),
        ),
      );

      await db.deleteCategory(travelId);

      final uncategorized = (await db.getAllCategories())
          .firstWhere((c) => c.name == uncategorizedCategoryName);
      final expenses = await db.getAllExpenses();

      expect(expenses.length, 1);
      expect(expenses.first.categoryId, uncategorized.id);

      await db.close();
    });

    test('ExpenseDataSource sanitizes expense name and rounds amount', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final dataSource = ExpenseDataSource(db);

      final categoryId = await db.insertCategory(
        CategoriesCompanion.insert(name: 'Food'),
      );

      await dataSource.addExpense(
        name: '  Lu@@nch!!  ',
        amount: 19.999,
        categoryId: categoryId,
        date: DateTime(2026, 6, 12),
      );

      final expenses = await db.getAllExpenses();

      expect(expenses.length, 1);
      expect(expenses.first.name, 'Lunch');
      expect(expenses.first.amount, 20.0);

      await db.close();
    });
  });
}
