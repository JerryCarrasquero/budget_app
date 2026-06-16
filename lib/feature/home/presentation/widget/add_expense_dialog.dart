import 'package:budget_app/core/database/app_database.dart';
import 'package:budget_app/core/text/app_text_provider.dart';
import 'package:budget_app/core/utils/input_sanitizer.dart';
import 'package:budget_app/feature/home/provider/home_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class AddExpenseDialog extends StatefulWidget {
  const AddExpenseDialog({
    super.key,
    required this.categories,
    required this.onSave,
  });

  final List<Category> categories;
  final Future<void> Function({
    String? name,
    required double amount,
    required int categoryId,
  }) onSave;

  @override
  State<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onChanged);
    _amountController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onChanged);
    _amountController.removeListener(_onChanged);
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final parsedAmount = InputSanitizer.parseAmount(_amountController.text);
    final canSave =
        parsedAmount != null &&
        parsedAmount > 0 &&
        _selectedCategoryId != null &&
        widget.categories.isNotEmpty;

    return AlertDialog(
      title: Text(text.addExpenseTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\s]')),
              LengthLimitingTextInputFormatter(50),
            ],
            decoration: InputDecoration(
              hintText: text.addExpenseNameHint,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              TextInputFormatter.withFunction((oldValue, newValue) {
                final next = newValue.text;
                final amountPattern = RegExp(r'^[0-9]*\.?[0-9]{0,2}');
                final fullMatch = amountPattern.matchAsPrefix(next)?.group(0) == next;
                if (next.isEmpty || fullMatch) {
                  return newValue;
                }
                return oldValue;
              }),
            ],
            decoration: InputDecoration(
              hintText: text.addExpenseAmountHint,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _selectedCategoryId,
            items: widget.categories
                .map(
                  (category) => DropdownMenuItem<int>(
                    value: category.id,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: Color(category.color),
                          child: Icon(
                            IconData(category.icon, fontFamily: 'MaterialIcons'),
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          fit: FlexFit.loose,
                          child: Text(
                            category.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _selectedCategoryId = value),
            decoration: InputDecoration(
              hintText: text.addExpenseCategoryHint,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(text.cancel),
        ),
        FilledButton(
          onPressed: canSave
              ? () async {
                  await widget.onSave(
                    name: InputSanitizer.sanitizeExpenseName(_nameController.text),
                    amount: parsedAmount,
                    categoryId: _selectedCategoryId!,
                  );
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                }
              : null,
          child: Text(text.save),
        ),
      ],
    );
  }
}

Future<void> showAddExpenseDialog(BuildContext context) async {
  final provider = context.read<HomeProvider>();
  final categories = await provider.loadCategoriesForDialog();

  if (!context.mounted) {
    return;
  }

  return showDialog<void>(
    context: context,
    builder: (_) => AddExpenseDialog(
      categories: List<Category>.from(categories),
      onSave: provider.addExpense,
    ),
  );
}
