import 'package:budget_app/core/database/app_database.dart';
import 'package:budget_app/core/text/app_text_provider.dart';
import 'package:flutter/material.dart';

class ExpenseDetailsDialog extends StatelessWidget {
  const ExpenseDetailsDialog({
    super.key,
    required this.expenseItem,
  });

  final ExpenseWithCategory expenseItem;

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final expense = expenseItem.expense;
    final category = expenseItem.category;
    final expenseName = expense.name?.trim().isNotEmpty == true
        ? expense.name!
        : text.unnamedCategoryExpense(category.name);

    final formattedDate =
        '${expense.date.year}-${expense.date.month.toString().padLeft(2, '0')}-${expense.date.day.toString().padLeft(2, '0')}';

    return AlertDialog(
      title: Text(text.expenseDetailsTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Color(category.color),
                child: Icon(
                  IconData(category.icon, fontFamily: 'MaterialIcons'),
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  expenseName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('${text.expenseAmountLabel}: ${expense.amount.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          Text('${text.expenseCategoryLabel}: ${category.name}'),
          const SizedBox(height: 8),
          Text('${text.expenseDateLabel}: $formattedDate'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(text.close),
        ),
      ],
    );
  }
}

Future<void> showExpenseDetailsDialog(
  BuildContext context, {
  required ExpenseWithCategory expenseItem,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => ExpenseDetailsDialog(expenseItem: expenseItem),
  );
}
