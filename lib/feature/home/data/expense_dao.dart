import 'package:budget_app/core/database/app_database.dart';
import 'package:drift/drift.dart';

class ExpenseDao {
  final AppDatabase db;
  ExpenseDao(this.db);

  Future<List<Expense>> getExpensesByMonth(int year, int month) async {
    final start = DateTime(year, month, 1);
    final end = (month < 12)
        ? DateTime(year, month + 1, 1)
        : DateTime(year + 1, 1, 1);
    return (db.select(db.expenses)
          ..where((tbl) => tbl.date.isBiggerOrEqualValue(start) & tbl.date.isSmallerThanValue(end)))
        .get();
  }
}
