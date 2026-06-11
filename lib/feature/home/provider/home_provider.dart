import 'dart:async';

import 'package:flutter/material.dart';
import 'package:budget_app/core/database/app_database.dart';
import 'package:budget_app/feature/home/data/expense_data_source.dart';
import 'package:budget_app/feature/home/domain/monthly_expenses.dart';

class HomeProvider extends ChangeNotifier {
  final ExpenseDataSource _dataSource;
  StreamSubscription<List<Category>>? _categoriesSubscription;
  StreamSubscription<List<Expense>>? _expensesSubscription;
  int _refreshRevision = 0;

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
    _categoriesSubscription = _dataSource.watchAllCategories().listen((
      categories,
    ) {
      _availableCategories = categories;
      _refreshCurrentMonthData();
    });

    _expensesSubscription = _dataSource.watchAllExpenses().listen((_) {
      _refreshCurrentMonthData();
    });

    _refreshCurrentMonthData();
  }

  int get selectedYear => _selectedYear;
  int get selectedMonth => _selectedMonth;
  bool get isLoading => _isLoading;
  List<Category> get availableCategories => _availableCategories;
  List<ExpenseWithCategory> get currentMonthlyExpenseItems =>
      _currentMonthlyExpenseItems;
  List<CategoryExpenseTotal> get categoryTotals => _categoryTotals;

  set selectedYear(int year) {
    _selectedYear = year;
    _refreshCurrentMonthData();
  }

  set selectedMonth(int month) {
    _selectedMonth = month;
    _refreshCurrentMonthData();
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
  }

  Future<List<Category>> loadCategoriesForDialog() async {
    if (_availableCategories.isNotEmpty) {
      return _availableCategories;
    }

    final categories = await _dataSource.getAllCategories();
    _availableCategories = categories;
    notifyListeners();
    return _availableCategories;
  }

  Future<void> loadCurrentMonthExpenses() async {
    await _refreshCurrentMonthData();
  }

  Future<void> _refreshCurrentMonthData() async {
    final currentRevision = ++_refreshRevision;
    _isLoading = true;
    notifyListeners();

    final selectedYear = _selectedYear;
    final selectedMonth = _selectedMonth;

    final expensesFuture = _dataSource.getExpensesByMonth(
      selectedYear,
      selectedMonth,
    );
    final expenseItemsFuture = _dataSource.getExpensesWithCategoryByMonth(
      selectedYear,
      selectedMonth,
    );
    final categoryTotalsFuture = _dataSource.getCategoryTotalsByMonth(
      selectedYear,
      selectedMonth,
    );

    final expenses = await expensesFuture;
    final expenseItems = await expenseItemsFuture;
    final categoryTotals = await categoryTotalsFuture;

    if (currentRevision != _refreshRevision) {
      return;
    }

    _currentMonthlyExpenses = MonthlyExpenses(
      year: selectedYear,
      month: selectedMonth,
      expenses: expenses,
    );
    _currentMonthlyExpenseItems = expenseItems;
    _categoryTotals = categoryTotals;
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _categoriesSubscription?.cancel();
    _expensesSubscription?.cancel();
    super.dispose();
  }
}
