import 'package:budget_app/core/database/app_database.dart';
import 'package:budget_app/core/utils/input_sanitizer.dart';
import 'package:drift/drift.dart';

class ExpenseDataSource {
  final AppDatabase _db;

  ExpenseDataSource(this._db);

  Future<List<Category>> getAllCategories() {
    return _db.getAllCategories();
  }

  Future<void> addExpense({
    String? name,
    required double amount,
    required int categoryId,
    DateTime? date,
  }) async {
    if (amount <= 0) {
      return;
    }

    final normalizedName = InputSanitizer.sanitizeExpenseName(name);
    await _db.insertExpense(
      ExpensesCompanion(
        name: normalizedName == null ? const Value.absent() : Value(normalizedName),
        amount: Value(double.parse(amount.toStringAsFixed(2))),
        date: Value(date ?? DateTime.now()),
        categoryId: Value(categoryId),
      ),
    );
  }

  Future<List<Expense>> getExpensesByMonth(int year, int month) async {
    final start = DateTime(year, month, 1);
    final end = (month < 12)
        ? DateTime(year, month + 1, 1)
        : DateTime(year + 1, 1, 1);
    return (_db.select(_db.expenses)
          ..where((tbl) => tbl.date.isBiggerOrEqualValue(start) & tbl.date.isSmallerThanValue(end)))
        .get();
  }

  Future<List<ExpenseWithCategory>> getExpensesWithCategoryByMonth(int year, int month) {
    return _db.getExpensesWithCategoryByMonth(year, month);
  }

  Future<List<CategoryExpenseTotal>> getCategoryTotalsByMonth(int year, int month) {
    return _db.getCategoryTotalsByMonth(year, month);
  }
}
