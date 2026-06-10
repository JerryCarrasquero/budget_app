import 'package:budget_app/core/database/app_database.dart';

class MonthlyExpenses {
  final int year;
  final int month;
  final List<Expense> expenses;

  MonthlyExpenses({
    required this.year,
    required this.month,
    required this.expenses,
  });
}
