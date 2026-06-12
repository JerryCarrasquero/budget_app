import 'package:drift/drift.dart';
import 'package:budget_app/core/database/connection/connection.dart';
import 'package:budget_app/core/constants/category_constants.dart';

part 'app_database.g.dart';

class ExpenseWithCategory {
  final Expense expense;
  final Category category;

  const ExpenseWithCategory({
    required this.expense,
    required this.category,
  });
}

class CategoryExpenseTotal {
  final Category category;
  final double total;

  const CategoryExpenseTotal({
    required this.category,
    required this.total,
  });
}

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get color => integer().withDefault(const Constant(0xFF42A5F5))();
  IntColumn get icon => integer().withDefault(const Constant(0xe88a))();
}

class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().nullable()();
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime()();
  IntColumn get categoryId => integer().references(Categories, #id)();
}

@DriftDatabase(tables: [Expenses, Categories])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(categories);
          }

          if (from < 3) {
            await customStatement(
              'ALTER TABLE categories ADD COLUMN color INTEGER NOT NULL DEFAULT 0xFF42A5F5',
            );
          }

          if (from < 4) {
            await customStatement(
              'ALTER TABLE categories ADD COLUMN icon INTEGER NOT NULL DEFAULT 0xe88a',
            );

            await customStatement('''
              INSERT INTO categories (name, color, icon)
              SELECT DISTINCT e.category, 0xFF42A5F5, 0xe88a
              FROM expenses e
              WHERE TRIM(COALESCE(e.category, '')) != ''
                AND NOT EXISTS (
                  SELECT 1
                  FROM categories c
                  WHERE LOWER(c.name) = LOWER(e.category)
                )
            ''');

            await customStatement('''
              INSERT INTO categories (name, color, icon)
              SELECT 'General', 0xFF42A5F5, 0xe88a
              WHERE NOT EXISTS (SELECT 1 FROM categories)
            ''');

            await customStatement('''
              CREATE TABLE expenses_new (
                id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
                name TEXT NULL,
                amount REAL NOT NULL,
                date INTEGER NOT NULL,
                category_id INTEGER NOT NULL REFERENCES categories(id)
              )
            ''');

            await customStatement('''
              INSERT INTO expenses_new (id, name, amount, date, category_id)
              SELECT
                e.id,
                NULLIF(TRIM(e.title), ''),
                e.amount,
                e.date,
                COALESCE(
                  (
                    SELECT c.id
                    FROM categories c
                    WHERE LOWER(c.name) = LOWER(e.category)
                    LIMIT 1
                  ),
                  (SELECT id FROM categories ORDER BY id LIMIT 1)
                )
              FROM expenses e
            ''');

            await customStatement('DROP TABLE expenses');
            await customStatement('ALTER TABLE expenses_new RENAME TO expenses');
          }
        },
      );

  // CRUD operations
  Future<List<Expense>> getAllExpenses() => select(expenses).get();
  Stream<List<Expense>> watchAllExpenses() => select(expenses).watch();
  Future<Expense?> getExpenseById(int id) {
    return (select(expenses)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Future<Map<DateTime, int>> getExpenseDayCounts() async {
    final dateColumn = expenses.date;
    final countColumn = expenses.id.count();

    final query = selectOnly(expenses)
      ..addColumns([dateColumn, countColumn])
      ..groupBy([dateColumn]);

    final rows = await query.get();
    final dayCounts = <DateTime, int>{};

    for (final row in rows) {
      final date = row.read(dateColumn);
      final count = row.read(countColumn);
      if (date == null || count == null) {
        continue;
      }

      final normalizedDay = DateTime(date.year, date.month, date.day);
      dayCounts[normalizedDay] = count;
    }

    return dayCounts;
  }

  Future<int> insertExpense(ExpensesCompanion expense) => into(expenses).insert(expense);
  Future<bool> updateExpense(Expense expense) => update(expenses).replace(expense);
  Future<int> deleteExpense(int id) => (delete(expenses)..where((tbl) => tbl.id.equals(id))).go();

  ({DateTime start, DateTime end}) _monthDateRange(int year, int month) {
    final start = DateTime(year, month, 1);
    final end = (month < 12)
        ? DateTime(year, month + 1, 1)
        : DateTime(year + 1, 1, 1);
    return (start: start, end: end);
  }

  void _validateRange(DateTime start, DateTime end) {
    if (!start.isBefore(end)) {
      throw ArgumentError('start must be before end');
    }
  }

  Future<List<ExpenseWithCategory>> getExpensesWithCategoryByPeriod(
    DateTime start,
    DateTime end,
  ) async {
    _validateRange(start, end);

    final joinedRows = await (select(expenses).join([
      innerJoin(categories, categories.id.equalsExp(expenses.categoryId)),
    ])
          ..where(expenses.date.isBiggerOrEqualValue(start) & expenses.date.isSmallerThanValue(end))
          ..orderBy([OrderingTerm.desc(expenses.date)]))
        .get();

    return joinedRows
        .map(
          (row) => ExpenseWithCategory(
            expense: row.readTable(expenses),
            category: row.readTable(categories),
          ),
        )
        .toList();
  }

  Future<List<ExpenseWithCategory>> getExpensesWithCategoryByMonth(int year, int month) async {
    final range = _monthDateRange(year, month);
    return getExpensesWithCategoryByPeriod(range.start, range.end);
  }

  Future<List<CategoryExpenseTotal>> getCategoryTotalsByPeriod(
    DateTime start,
    DateTime end,
  ) async {
    _validateRange(start, end);

    final rows = await customSelect(
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
      readsFrom: {categories, expenses},
    ).get();

    return rows
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
        .toList();
  }

  Future<List<CategoryExpenseTotal>> getCategoryTotalsByMonth(int year, int month) async {
    final range = _monthDateRange(year, month);
    return getCategoryTotalsByPeriod(range.start, range.end);
  }

  Future<List<Category>> getAllCategories() => select(categories).get();
  Stream<List<Category>> watchAllCategories() => select(categories).watch();
  Future<int> insertCategory(CategoriesCompanion category) => into(categories).insert(category);

  Future<int> ensureUncategorizedCategory() async {
    final existing = await (select(categories)
          ..where((tbl) => tbl.name.lower().equals(uncategorizedCategoryName.toLowerCase())))
        .getSingleOrNull();

    if (existing != null) {
      return existing.id;
    }

    return into(categories).insert(
      CategoriesCompanion(
        name: const Value(uncategorizedCategoryName),
        color: const Value(uncategorizedCategoryColor),
        icon: const Value(uncategorizedCategoryIconCodePoint),
      ),
    );
  }

  Future<int> deleteCategory(int id) async {
    final uncategorizedId = await ensureUncategorizedCategory();
    if (id == uncategorizedId) {
      return 0;
    }

    await (update(expenses)..where((tbl) => tbl.categoryId.equals(id))).write(
      ExpensesCompanion(categoryId: Value(uncategorizedId)),
    );

    return (delete(categories)..where((tbl) => tbl.id.equals(id))).go();
  }
}
