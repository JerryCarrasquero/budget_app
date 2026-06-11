import 'package:budget_app/feature/categories/presentation/screen/categories_page.dart';
import 'package:budget_app/core/text/app_text_provider.dart';
import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final text = context.text;

    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(child: Text(text.menuTitle)),
          ListTile(
            leading: const Icon(Icons.category),
            title: Text(text.categories),
            onTap: () async {
              Navigator.of(context).pop();
              await Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const CategoriesPage()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.repeat),
            title: Text(text.recurringExpenses),
            onTap: () {
              // TODO: Navigate to recurring expenses page
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: Text(text.statistics),
            onTap: () {
              // TODO: Navigate to statistics/graphs page
            },
          ),
        ],
      ),
    );
  }
}
