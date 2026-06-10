import 'package:budget_app/core/text/app_texts.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AppTextProvider {
  const AppTextProvider();

  String get appTitle => AppTexts.appTitle;
  String get menuTitle => AppTexts.menuTitle;
  String get categories => AppTexts.categories;
  String get recurringExpenses => AppTexts.recurringExpenses;
  String get statistics => AppTexts.statistics;
  String get currentMonth => AppTexts.currentMonth;
  String get totalSpent => AppTexts.totalSpent;
  String get expenses => AppTexts.expenses;
  String get noWheelData => AppTexts.noWheelData;
  String get expenseDetailsTitle => AppTexts.expenseDetailsTitle;
  String get expenseAmountLabel => AppTexts.expenseAmountLabel;
  String get expenseCategoryLabel => AppTexts.expenseCategoryLabel;
  String get expenseDateLabel => AppTexts.expenseDateLabel;
  String get close => AppTexts.close;
  String get addExpenseTitle => AppTexts.addExpenseTitle;
  String get addExpenseNameHint => AppTexts.addExpenseNameHint;
  String get addExpenseAmountHint => AppTexts.addExpenseAmountHint;
  String get addExpenseCategoryHint => AppTexts.addExpenseCategoryHint;
  String get addCategoryTitle => AppTexts.addCategoryTitle;
  String get addCategoryHint => AppTexts.addCategoryHint;
  String get cancel => AppTexts.cancel;
  String get save => AppTexts.save;
  String get noCategoriesYet => AppTexts.noCategoriesYet;
  List<String> get monthNames => AppTexts.monthNames;

  String unnamedCategoryExpense(String category) =>
      AppTexts.unnamedCategoryExpense(category);

  String categoryTotalLabel(String category, double total) =>
      AppTexts.categoryTotalLabel(category, total);

  String wheelLegendLabel(String category, double total) =>
      AppTexts.wheelLegendLabel(category, total);
}

extension AppTextContextX on BuildContext {
  AppTextProvider get text => read<AppTextProvider>();
}
