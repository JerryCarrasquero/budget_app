import 'package:budget_app/feature/categories/presentation/provider/categories_provider.dart';
import 'package:budget_app/core/constants/category_constants.dart';
import 'package:budget_app/core/text/app_text_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CategoriesBody extends StatelessWidget {
  const CategoriesBody({super.key});

  @override
  Widget build(BuildContext context) {
    final text = context.text;

    return Consumer<CategoriesProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.categories.isEmpty) {
          return Center(
            child: Text(text.noCategoriesYet),
          );
        }

        final visibleCategories = provider.categories
            .where((category) => category.name != uncategorizedCategoryName)
            .toList();

        return ListView.builder(
          itemCount: visibleCategories.length,
          itemBuilder: (context, index) {
            final category = visibleCategories[index];
            return ListTile(
              leading: CircleAvatar(
                radius: 14,
                backgroundColor: Color(category.color),
                child: Icon(
                  IconData(category.icon, fontFamily: 'MaterialIcons'),
                  color: Colors.white,
                  size: 16,
                ),
              ),
              title: Text(category.name),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => provider.deleteCategory(category.id),
              ),
            );
          },
        );
      },
    );
  }
}
