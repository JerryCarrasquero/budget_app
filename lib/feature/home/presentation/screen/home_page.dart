import 'package:flutter/material.dart';
import 'package:budget_app/core/database/app_database.dart';
import 'package:budget_app/core/text/app_text_provider.dart';
import 'package:budget_app/feature/home/presentation/provider/home_provider.dart';
import 'package:budget_app/feature/home/presentation/widget/add_expense_dialog.dart';
import 'package:budget_app/feature/home/presentation/widget/app_drawer.dart';
import 'package:budget_app/feature/home/presentation/widget/category_wheel_chart.dart';
import 'package:budget_app/feature/home/presentation/widget/expense_details_dialog.dart';
import 'package:provider/provider.dart';
class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => HomeProvider(context.read<AppDatabase>()),
      child: Consumer<HomeProvider>(
        builder: (context, provider, _) {
          final text = context.text;
          final monthNames = text.monthNames;
          final currentMonth = provider.selectedMonth;
          final currentYear = provider.selectedYear;
          final expenses = provider.currentMonthlyExpenses.expenses;
          final expenseItems = provider.currentMonthlyExpenseItems;
          final groupedByCategory = provider.categoryTotals.where((item) => item.total > 0).toList();
          final totalSpent = expenses.fold<double>(0, (sum, e) => sum + e.amount);
          return Scaffold(
            appBar: AppBar(
              title: Text(text.appTitle),
              actions: [
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () {
                    // TODO: Show month/year picker
                  },
                ),
              ],
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(text.currentMonth, style: Theme.of(context).textTheme.bodySmall),
                          Text(
                            '${monthNames[currentMonth]} $currentYear',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(text.totalSpent, style: Theme.of(context).textTheme.bodySmall),
                          Text(
                            totalSpent.toStringAsFixed(2),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                    ],
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
                            subtitle: Text('${expense.date.year}-${expense.date.month.toString().padLeft(2, '0')}-${expense.date.day.toString().padLeft(2, '0')}'),
                            trailing: Text(expense.amount.toStringAsFixed(2)),
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
