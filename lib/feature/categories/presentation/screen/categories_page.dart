import 'package:budget_app/feature/categories/provider/categories_provider.dart';
import 'package:budget_app/feature/categories/presentation/widget/add_category_dialog.dart';
import 'package:budget_app/feature/categories/presentation/widget/categories_body.dart';
import 'package:budget_app/core/database/app_database.dart';
import 'package:budget_app/core/text/app_text_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CategoriesProvider(context.read<AppDatabase>()),
      child: const _CategoriesView(),
    );
  }
}

class _CategoriesView extends StatelessWidget {
  const _CategoriesView();

  @override
  Widget build(BuildContext context) {
    final text = context.text;

    return Scaffold(
      appBar: AppBar(
        title: Text(text.categories),
      ),
      body: const CategoriesBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddCategoryDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
