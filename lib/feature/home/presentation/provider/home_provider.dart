import 'package:flutter/material.dart';
import 'package:budget_app/core/database/app_database.dart';
import 'package:budget_app/feature/home/data/expense_data_source.dart';
import 'package:budget_app/feature/home/domain/monthly_expenses.dart';

class HomeProvider extends ChangeNotifier {
  final ExpenseDataSource _dataSource;

  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  MonthlyExpenses _currentMonthlyExpenses = MonthlyExpenses(
    year: DateTime.now().year,
    month: DateTime.now().month,
    expenses: [],
  );
  List<Category> _availableCategories = [];
  List<ExpenseWithCategory> _currentMonthlyExpenseItems = [];
  List<CategoryExpenseTotal> _categoryTotals = [];
  bool _isLoading = false;

  HomeProvider(AppDatabase database)
      : _dataSource = ExpenseDataSource(database) {
    loadCurrentMonthExpenses();
  }

  int get selectedYear => _selectedYear;
  int get selectedMonth => _selectedMonth;
  bool get isLoading => _isLoading;
  List<Category> get availableCategories => _availableCategories;
  List<ExpenseWithCategory> get currentMonthlyExpenseItems => _currentMonthlyExpenseItems;
  List<CategoryExpenseTotal> get categoryTotals => _categoryTotals;

  set selectedYear(int year) {
    _selectedYear = year;
    loadCurrentMonthExpenses();
  }

  set selectedMonth(int month) {
    _selectedMonth = month;
    loadCurrentMonthExpenses();
  }

  MonthlyExpenses get currentMonthlyExpenses => _currentMonthlyExpenses;

  Future<void> addExpense({
    String? name,
    required double amount,
    required int categoryId,
  }) async {
    await _dataSource.addExpense(
      name: name,
      amount: amount,
      categoryId: categoryId,
    );
    await loadCurrentMonthExpenses();
  }

  Future<List<Category>> loadCategoriesForDialog() async {
    final categories = await _dataSource.getAllCategories();
    _availableCategories = categories;
    notifyListeners();
    return categories;
  }

  Future<void> loadCurrentMonthExpenses() async {
    _isLoading = true;
    notifyListeners();

    _availableCategories = await _dataSource.getAllCategories();
    final expenses = await _dataSource.getExpensesByMonth(_selectedYear, _selectedMonth);
    _currentMonthlyExpenseItems = await _dataSource.getExpensesWithCategoryByMonth(_selectedYear, _selectedMonth);
    _categoryTotals = await _dataSource.getCategoryTotalsByMonth(_selectedYear, _selectedMonth);
    _currentMonthlyExpenses = MonthlyExpenses(
      year: _selectedYear,
      month: _selectedMonth,
      expenses: expenses,
    );

    _isLoading = false;
    notifyListeners();
  }
}
