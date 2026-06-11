import 'package:budget_app/feature/categories/provider/categories_provider.dart';
import 'package:budget_app/feature/categories/domain/add_category_result.dart';
import 'package:budget_app/core/text/app_text_provider.dart';
import 'package:budget_app/core/utils/input_sanitizer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class AddCategoryDialog extends StatefulWidget {
  const AddCategoryDialog({
    super.key,
    required this.controller,
    required this.onSave,
    required this.isDuplicateName,
  });

  final TextEditingController controller;
  final Future<AddCategoryResult> Function(String name, int color, int icon)
  onSave;
  final bool Function(String sanitizedName) isDuplicateName;

  @override
  State<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  static const List<int> _presetColors = [
    0xFFE53935,
    0xFFFF7043,
    0xFFFBC02D,
    0xFF43A047,
    0xFF00897B,
    0xFF1E88E5,
    0xFF5E35B1,
    0xFFD81B60,
  ];

  int? _selectedColor;
  int? _selectedIcon;
  bool _submitted = false;

  static const List<IconData> _presetIcons = [
    Icons.fastfood,
    Icons.directions_bus,
    Icons.home,
    Icons.local_hospital,
    Icons.school,
    Icons.shopping_bag,
    Icons.sports_esports,
    Icons.work,
  ];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onNameChanged);
    super.dispose();
  }

  void _onNameChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final sanitizedName = InputSanitizer.sanitizeCategoryName(
      widget.controller.text,
    );
    final hasInvalidCharacters =
        widget.controller.text.trim().isNotEmpty && sanitizedName.isEmpty;
    final hasDuplicate =
        sanitizedName.isNotEmpty && widget.isDuplicateName(sanitizedName);
    final nameErrorText = hasInvalidCharacters
        ? text.categoryNameInvalid
        : (_submitted && sanitizedName.isEmpty)
        ? text.categoryNameRequired
        : hasDuplicate
        ? text.categoryNameDuplicate
        : null;
    final canSave =
        sanitizedName.isNotEmpty &&
        !hasDuplicate &&
        !hasInvalidCharacters &&
        _selectedColor != null &&
        _selectedIcon != null;

    return AlertDialog(
      title: Text(text.addCategoryTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: widget.controller,
            autofocus: false,
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\s]')),
              LengthLimitingTextInputFormatter(40),
            ],
            decoration: InputDecoration(
              hintText: text.addCategoryHint,
              errorText: nameErrorText,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _presetColors
                .map(
                  (colorValue) => InkWell(
                    onTap: () => setState(() => _selectedColor = colorValue),
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(colorValue),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _selectedColor == colorValue
                              ? Colors.black
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _presetIcons
                .map(
                  (icon) => InkWell(
                    onTap: () => setState(() => _selectedIcon = icon.codePoint),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedIcon == icon.codePoint
                              ? Colors.black
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: Color(_selectedColor ?? Colors.blue.toARGB32()),
                      ),
                    ),
                  ),
                )
                .toList(),
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
                  setState(() => _submitted = true);
                  final name = InputSanitizer.sanitizeCategoryName(
                    widget.controller.text,
                  );
                  final result = await widget.onSave(
                    name,
                    _selectedColor!,
                    _selectedIcon!,
                  );
                  if (!context.mounted) {
                    return;
                  }

                  if (result == AddCategoryResult.success) {
                    Navigator.of(context).pop();
                    return;
                  }

                  final message = switch (result) {
                    AddCategoryResult.invalidName => text.categoryNameInvalid,
                    AddCategoryResult.duplicate => text.categoryNameDuplicate,
                    AddCategoryResult.failure => text.categorySaveFailed,
                    AddCategoryResult.success => null,
                  };

                  if (message != null) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(message)));
                  }
                }
              : null,
          child: Text(text.save),
        ),
      ],
    );
  }
}

Future<void> showAddCategoryDialog(BuildContext context) async {
  final controller = TextEditingController();
  final categoriesProvider = context.read<CategoriesProvider>();

  await showDialog<void>(
    context: context,
    builder: (_) => AddCategoryDialog(
      controller: controller,
      onSave: categoriesProvider.addCategory,
      isDuplicateName: (sanitizedName) => categoriesProvider.categories.any(
        (category) =>
            category.name.toLowerCase() == sanitizedName.toLowerCase(),
      ),
    ),
  );

  controller.dispose();
}
