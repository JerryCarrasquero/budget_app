import 'package:budget_app/core/database/app_database.dart';
import 'package:budget_app/core/utils/input_sanitizer.dart';
import 'package:drift/drift.dart';

class ExpenseDataSource {
  final AppDatabase _db;

  ExpenseDataSource(this._db);

  Future<List<Category>> getAllCategories() {
    return _db.getAllCategories();
  }

  Stream<List<Category>> watchAllCategories() {
    return _db.watchAllCategories();
  }

  Stream<List<Expense>> watchAllExpenses() {
    return _db.watchAllExpenses();
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
        name: normalizedName == null
            ? const Value.absent()
            : Value(normalizedName),
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
    return (_db.select(_db.expenses)..where(
          (tbl) =>
              tbl.date.isBiggerOrEqualValue(start) &
              tbl.date.isSmallerThanValue(end),
        ))
        .get();
  }

  Stream<List<Expense>> watchExpensesByMonth(int year, int month) {
    final start = DateTime(year, month, 1);
    final end = (month < 12)
        ? DateTime(year, month + 1, 1)
        : DateTime(year + 1, 1, 1);

    return (_db.select(_db.expenses)..where(
          (tbl) =>
              tbl.date.isBiggerOrEqualValue(start) &
              tbl.date.isSmallerThanValue(end),
        ))
        .watch();
  }

  Future<List<ExpenseWithCategory>> getExpensesWithCategoryByMonth(
    int year,
    int month,
  ) {
    return _db.getExpensesWithCategoryByMonth(year, month);
  }

  Stream<List<ExpenseWithCategory>> watchExpensesWithCategoryByMonth(
    int year,
    int month,
  ) {
    final start = DateTime(year, month, 1);
    final end = (month < 12)
        ? DateTime(year, month + 1, 1)
        : DateTime(year + 1, 1, 1);

    return (_db.select(_db.expenses).join([
            innerJoin(
              _db.categories,
              _db.categories.id.equalsExp(_db.expenses.categoryId),
            ),
          ])
          ..where(
            _db.expenses.date.isBiggerOrEqualValue(start) &
                _db.expenses.date.isSmallerThanValue(end),
          )
          ..orderBy([OrderingTerm.desc(_db.expenses.date)]))
        .watch()
        .map(
          (rows) => rows
              .map(
                (row) => ExpenseWithCategory(
                  expense: row.readTable(_db.expenses),
                  category: row.readTable(_db.categories),
                ),
              )
              .toList(),
        );
  }

  Future<List<CategoryExpenseTotal>> getCategoryTotalsByMonth(
    int year,
    int month,
  ) {
    return _db.getCategoryTotalsByMonth(year, month);
  }

  Stream<List<CategoryExpenseTotal>> watchCategoryTotalsByMonth(
    int year,
    int month,
  ) {
    final start = DateTime(year, month, 1);
    final end = (month < 12)
        ? DateTime(year, month + 1, 1)
        : DateTime(year + 1, 1, 1);

    return _db
        .customSelect(
          '''
          SELECT c.id, c.name, c.color, c.icon, COALESCE(SUM(e.amount), 0) AS total
          FROM categories c
          LEFT JOIN expenses e
            ON e.category_id = c.id
           AND e.date >= ?
           AND e.date < ?
          GROUP BY c.id, c.name, c.color, c.icon
          ORDER BY total DESC, c.name ASC
          ''',
          variables: [Variable<DateTime>(start), Variable<DateTime>(end)],
          readsFrom: {_db.categories, _db.expenses},
        )
        .watch()
        .map(
          (rows) => rows
              .map(
                (row) => CategoryExpenseTotal(
                  category: Category(
                    id: row.read<int>('id'),
                    name: row.read<String>('name'),
                    color: row.read<int>('color'),
                    icon: row.read<int>('icon'),
                  ),
                  total: row.read<double>('total'),
                ),
              )
              .toList(),
        );
  }
}
