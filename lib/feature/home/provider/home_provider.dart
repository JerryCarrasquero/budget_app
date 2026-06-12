import 'dart:async';

import 'package:flutter/material.dart';
import 'package:budget_app/core/database/app_database.dart';
import 'package:budget_app/feature/home/data/expense_data_source.dart';
import 'package:budget_app/feature/home/domain/monthly_expenses.dart';

enum HomePeriodMode { month, day, monthRange }

class HomeProvider extends ChangeNotifier {
  final ExpenseDataSource _dataSource;
  StreamSubscription<List<Category>>? _categoriesSubscription;
  StreamSubscription<List<Expense>>? _expensesSubscription;
  int _refreshRevision = 0;
  bool _isDisposed = false;

  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  HomePeriodMode _periodMode = HomePeriodMode.month;
  DateTime _periodStart = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _periodEnd = DateTime(DateTime.now().year, DateTime.now().month + 1, 1);
  MonthlyExpenses _currentMonthlyExpenses = MonthlyExpenses(
    year: DateTime.now().year,
    month: DateTime.now().month,
    expenses: [],
  );
  List<Category> _availableCategories = [];
  List<ExpenseWithCategory> _currentMonthlyExpenseItems = [];
  List<CategoryExpenseTotal> _categoryTotals = [];
  Map<DateTime, int> _expenseDayCounts = <DateTime, int>{};
  Set<DateTime> _expenseDaysForCalendar = <DateTime>{};
  bool _expenseDaysLoaded = false;
  bool _isLoading = false;

  HomeProvider(AppDatabase database)
    : _dataSource = ExpenseDataSource(database) {
    _categoriesSubscription = _dataSource.watchAllCategories().listen((
      categories,
    ) {
      _availableCategories = categories;
      _refreshCurrentPeriodData();
    });

    _subscribeToCurrentPeriodExpenses();

    _refreshCurrentPeriodData();
    _loadExpenseDaysForCalendarIfNeeded();
  }

  int get selectedYear => _selectedYear;
  int get selectedMonth => _selectedMonth;
  HomePeriodMode get periodMode => _periodMode;
  DateTime get periodStart => _periodStart;
  DateTime get periodEnd => _periodEnd;
  bool get isLoading => _isLoading;
  List<Category> get availableCategories => _availableCategories;
  List<ExpenseWithCategory> get currentMonthlyExpenseItems =>
      _currentMonthlyExpenseItems;
  List<CategoryExpenseTotal> get categoryTotals => _categoryTotals;
  Set<DateTime> get expenseDaysForCalendar => _expenseDaysForCalendar;

  set selectedYear(int year) {
    setMonthPeriod(year, _selectedMonth);
  }

  set selectedMonth(int month) {
    setMonthPeriod(_selectedYear, month);
  }

  void setMonthPeriod(int year, int month) {
    _selectedYear = year;
    _selectedMonth = month;
    _periodMode = HomePeriodMode.month;
    _periodStart = DateTime(year, month, 1);
    _periodEnd = (month < 12)
        ? DateTime(year, month + 1, 1)
        : DateTime(year + 1, 1, 1);
    _subscribeToCurrentPeriodExpenses();
    _refreshCurrentPeriodData();
  }

  void setDayPeriod(DateTime day) {
    _periodMode = HomePeriodMode.day;
    _periodStart = DateTime(day.year, day.month, day.day);
    _periodEnd = _periodStart.add(const Duration(days: 1));
    _selectedYear = day.year;
    _selectedMonth = day.month;
    _subscribeToCurrentPeriodExpenses();
    _refreshCurrentPeriodData();
  }

  void setMonthRangePeriod({
    required int startYear,
    required int startMonth,
    required int endYear,
    required int endMonth,
  }) {
    setDateRangePeriod(
      start: DateTime(startYear, startMonth, 1),
      end: DateTime(endYear, endMonth + 1, 1),
    );
  }

  void setDateRangePeriod({
    required DateTime start,
    required DateTime end,
  }) {
    final normalizedStart = DateTime(start.year, start.month, start.day);
    final normalizedEnd = DateTime(end.year, end.month, end.day);

    if (!normalizedStart.isBefore(normalizedEnd)) {
      return;
    }

    _periodMode = HomePeriodMode.monthRange;
    _periodStart = normalizedStart;
    _periodEnd = normalizedEnd;
    _selectedYear = normalizedStart.year;
    _selectedMonth = normalizedStart.month;
    _subscribeToCurrentPeriodExpenses();
    _refreshCurrentPeriodData();
  }

  MonthlyExpenses get currentMonthlyExpenses => _currentMonthlyExpenses;

  Future<void> addExpense({
    String? name,
    required double amount,
    required int categoryId,
    DateTime? date,
  }) async {
    final expenseDate = date ?? DateTime.now();
    final inserted = await _dataSource.addExpense(
      name: name,
      amount: amount,
      categoryId: categoryId,
      date: expenseDate,
    );

    if (inserted) {
      _incrementExpenseDay(expenseDate);
    }
  }

  Future<bool> updateExpense(Expense updatedExpense) async {
    final existingExpense = await _dataSource.getExpenseById(updatedExpense.id);
    if (existingExpense == null) {
      return false;
    }

    final updated = await _dataSource.updateExpense(updatedExpense);
    if (!updated) {
      return false;
    }

    final oldDay = _normalizeDay(existingExpense.date);
    final newDay = _normalizeDay(updatedExpense.date);

    if (oldDay != newDay) {
      _decrementExpenseDay(oldDay);
      _incrementExpenseDay(newDay);
    }

    return true;
  }

  Future<bool> deleteExpense(int expenseId) async {
    final existingExpense = await _dataSource.getExpenseById(expenseId);
    if (existingExpense == null) {
      return false;
    }

    final deletedRows = await _dataSource.deleteExpense(expenseId);
    if (deletedRows <= 0) {
      return false;
    }

    _decrementExpenseDay(existingExpense.date);
    return true;
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
    await _refreshCurrentPeriodData();
  }

  Future<Set<DateTime>> loadExpenseDaysForCalendar() async {
    await _loadExpenseDaysForCalendarIfNeeded();
    return _expenseDaysForCalendar;
  }

  Future<void> preloadExpenseDaysForCalendar() async {
    await _loadExpenseDaysForCalendarIfNeeded();
  }

  Future<void> _loadExpenseDaysForCalendarIfNeeded() async {
    if (_expenseDaysLoaded) {
      return;
    }

    final dayCounts = await _dataSource.getExpenseDayCounts();
    if (_isDisposed) {
      return;
    }

    _expenseDayCounts = dayCounts;
    _expenseDaysForCalendar = dayCounts.keys.toSet();
    _expenseDaysLoaded = true;
  }

  DateTime _normalizeDay(DateTime date) => DateTime(date.year, date.month, date.day);

  void _incrementExpenseDay(DateTime date) {
    final day = _normalizeDay(date);
    final previousCount = _expenseDayCounts[day] ?? 0;
    _expenseDayCounts[day] = previousCount + 1;

    if (previousCount == 0) {
      _expenseDaysForCalendar = {..._expenseDaysForCalendar, day};
      _notifySafely();
    }
  }

  void _decrementExpenseDay(DateTime date) {
    final day = _normalizeDay(date);
    final previousCount = _expenseDayCounts[day] ?? 0;
    if (previousCount <= 0) {
      return;
    }

    if (previousCount == 1) {
      _expenseDayCounts.remove(day);
      final nextDays = {..._expenseDaysForCalendar};
      if (nextDays.remove(day)) {
        _expenseDaysForCalendar = nextDays;
        _notifySafely();
      }
      return;
    }

    _expenseDayCounts[day] = previousCount - 1;
  }

  Future<void> _refreshCurrentPeriodData() async {
    final currentRevision = ++_refreshRevision;
    _isLoading = true;
    _notifySafely();

    final selectedYear = _selectedYear;
    final selectedMonth = _selectedMonth;

    final Future<List<Expense>> expensesFuture;
    final Future<List<ExpenseWithCategory>> expenseItemsFuture;
    final Future<List<CategoryExpenseTotal>> categoryTotalsFuture;

    if (_periodMode == HomePeriodMode.month) {
      expensesFuture = _dataSource.getExpensesByMonth(selectedYear, selectedMonth);
      expenseItemsFuture = _dataSource.getExpensesWithCategoryByMonth(
        selectedYear,
        selectedMonth,
      );
      categoryTotalsFuture = _dataSource.getCategoryTotalsByMonth(
        selectedYear,
        selectedMonth,
      );
    } else {
      expensesFuture = _dataSource.getExpensesByPeriod(_periodStart, _periodEnd);
      expenseItemsFuture = _dataSource.getExpensesWithCategoryByPeriod(
        _periodStart,
        _periodEnd,
      );
      categoryTotalsFuture = _dataSource.getCategoryTotalsByPeriod(
        _periodStart,
        _periodEnd,
      );
    }

    try {
      final expenses = await expensesFuture;
      final expenseItems = await expenseItemsFuture;
      final categoryTotals = await categoryTotalsFuture;

      if (currentRevision != _refreshRevision || _isDisposed) {
        return;
      }

      _currentMonthlyExpenses = MonthlyExpenses(
        year: selectedYear,
        month: selectedMonth,
        expenses: expenses,
      );
      _currentMonthlyExpenseItems = expenseItems;
      _categoryTotals = categoryTotals;
    } finally {
      if (currentRevision == _refreshRevision && !_isDisposed) {
        _isLoading = false;
        _notifySafely();
      }
    }
  }

  void _subscribeToCurrentPeriodExpenses() {
    _expensesSubscription?.cancel();

    if (_periodMode == HomePeriodMode.month) {
      _expensesSubscription = _dataSource
          .watchExpensesByMonth(_selectedYear, _selectedMonth)
          .listen((_) {
            _refreshCurrentPeriodData();
          });
      return;
    }

    _expensesSubscription = _dataSource
        .watchExpensesByPeriod(_periodStart, _periodEnd)
        .listen((_) {
          _refreshCurrentPeriodData();
        });
  }

  void _notifySafely() {
    if (_isDisposed) {
      return;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _categoriesSubscription?.cancel();
    _expensesSubscription?.cancel();
    super.dispose();
  }
}
