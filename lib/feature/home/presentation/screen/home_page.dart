import 'package:flutter/material.dart';
import 'package:budget_app/core/database/app_database.dart';
import 'package:budget_app/core/text/app_text_provider.dart';
import 'package:budget_app/feature/home/provider/home_provider.dart';
import 'package:budget_app/feature/home/presentation/widget/add_expense_dialog.dart';
import 'package:budget_app/feature/home/presentation/widget/app_drawer.dart';
import 'package:budget_app/feature/home/presentation/widget/category_wheel_chart.dart';
import 'package:budget_app/feature/home/presentation/widget/expense_details_dialog.dart';
import 'package:budget_app/feature/home/presentation/widget/home_period_calendar_button.dart';
import 'package:budget_app/feature/home/presentation/widget/home_period_header.dart';
import 'package:provider/provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  DateTime _monthEndExclusive(DateTime date) {
    return (date.month < 12)
        ? DateTime(date.year, date.month + 1, 1)
        : DateTime(date.year + 1, 1, 1);
  }

  String _buildPeriodLabel(BuildContext context, HomeProvider provider, List<String> monthNames) {
    final localizations = MaterialLocalizations.of(context);

    DateTime displayStart = provider.periodStart;
    DateTime displayEndExclusive = provider.periodEnd;
    final endInclusive = displayEndExclusive.subtract(const Duration(days: 1));

    if (endInclusive.isAtSameMomentAs(displayStart)) {
      return localizations.formatShortDate(displayStart);
    }

    if (provider.periodMode == HomePeriodMode.month) {
      return '${monthNames[provider.selectedMonth]} ${provider.selectedYear}';
    }

    final isFullMonth = displayStart.day == 1 && displayEndExclusive == _monthEndExclusive(displayStart);
    if (isFullMonth) {
      final startMonth = monthNames[displayStart.month];
      if (displayStart.year == endInclusive.year && displayStart.month == endInclusive.month) {
        return '$startMonth ${displayStart.year}';
      }
      return '$startMonth ${displayStart.year} - ${monthNames[endInclusive.month]} ${endInclusive.year}';
    }

    final useShortDates = displayStart.month != endInclusive.month ||
        displayStart.year != endInclusive.year ||
        endInclusive.difference(displayStart).inDays > 30;

    if (useShortDates) {
      return '${localizations.formatShortDate(displayStart)} - ${localizations.formatShortDate(endInclusive)}';
    }

    return '${monthNames[displayStart.month]} ${displayStart.day} - ${monthNames[endInclusive.month]} ${endInclusive.day}, ${endInclusive.year}';
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => HomeProvider(context.read<AppDatabase>()),
      child: Consumer<HomeProvider>(
        builder: (context, provider, _) {
          final text = context.text;
          final monthNames = text.monthNames;
          final periodLabel = _buildPeriodLabel(context, provider, monthNames);
          final periodTitle = provider.periodMode == HomePeriodMode.month
              ? text.currentMonth
              : text.selectedPeriod;
          final expenses = provider.currentMonthlyExpenses.expenses;
          final expenseItems = provider.currentMonthlyExpenseItems;
          final groupedByCategory = provider.categoryTotals.where((item) => item.total > 0).toList();
          final totalSpent = expenses.fold<double>(0, (sum, e) => sum + e.amount);
          return Scaffold(
            appBar: AppBar(
              title: Text(text.appTitle),
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HomePeriodHeader(
                    periodTitle: periodTitle,
                    periodLabel: periodLabel,
                    trailing: HomePeriodCalendarButton(provider: provider),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(text.totalSpent, style: Theme.of(context).textTheme.bodySmall),
                        Text(
                          totalSpent.toStringAsFixed(2),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  CategoryWheelChart(categoryTotals: groupedByCategory),
                  const SizedBox(height: 12),
                  if (groupedByCategory.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: groupedByCategory
                          .map(
                            (item) => Chip(
                              backgroundColor: Color(item.category.color),
                              avatar: Icon(
                                IconData(item.category.icon, fontFamily: 'MaterialIcons'),
                                color: Colors.white,
                                size: 16,
                              ),
                              label: Text(text.categoryTotalLabel(item.category.name, item.total)),
                            ),
                          )
                          .toList(),
                    ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(text.expenses, style: Theme.of(context).textTheme.titleLarge),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          showAddExpenseDialog(context);
                        },
                      ),
                    ],
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: expenseItems.length,
                      itemBuilder: (context, index) {
                        final expenseItem = expenseItems[index];
                        final expense = expenseItem.expense;
                        final category = expenseItem.category;
                        final expenseDateLabel = MaterialLocalizations.of(
                          context,
                        ).formatShortDate(expense.date);
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Color(category.color),
                              child: Icon(
                                IconData(category.icon, fontFamily: 'MaterialIcons'),
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            title: Text(
                              expense.name?.trim().isNotEmpty == true
                                  ? expense.name!
                                  : text.unnamedCategoryExpense(category.name),
                            ),
                            trailing: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  expenseDateLabel,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 2),
                                Text(expense.amount.toStringAsFixed(2)),
                              ],
                            ),
                            onTap: () {
                              showExpenseDetailsDialog(
                                context,
                                expenseItem: expenseItem,
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            drawer: const AppDrawer(),
          );
        },
      ),
    );
  }
}
