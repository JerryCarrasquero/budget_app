import 'package:budget_app/core/database/app_database.dart';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';

const bool seedDemo = bool.fromEnvironment('SEED_DEMO', defaultValue: false);
const bool resetDemo = bool.fromEnvironment('RESET_DEMO', defaultValue: false);

Future<void> runDemoSeedSetupIfEnabled(AppDatabase db) async {
  if (!seedDemo && !resetDemo) {
    return;
  }

  final seeder = DemoSeeder(db);
  if (resetDemo) {
    await seeder.clearAll();
  }

  if (seedDemo) {
    await seeder.seedIfEmpty();
  }
}

class DemoSeeder {
  final AppDatabase _db;

  const DemoSeeder(this._db);

  Future<void> clearAll() async {
    await _db.transaction(() async {
      await _db.delete(_db.expenses).go();
      await _db.delete(_db.categories).go();
    });
  }

  Future<void> seedIfEmpty() async {
    final existingExpenses = await _db.getAllExpenses();
    if (existingExpenses.isNotEmpty) {
      return;
    }

    await _db.transaction(() async {
      await _db.ensureUncategorizedCategory();

      final requiredCategories = <_CategorySeed>[
        _CategorySeed('TCG', 0xFFE53935, Icons.style.codePoint),
        _CategorySeed('clothes', 0xFF8E24AA, Icons.checkroom.codePoint),
        _CategorySeed('cleaning supply', 0xFFC0C0C0, Icons.cleaning_services.codePoint),
        _CategorySeed('pet', 0xFFFDD835, Icons.pets.codePoint),
        _CategorySeed('furniture', 0xFF8D6E63, Icons.chair.codePoint),
      ];

      final currentCategories = await _db.getAllCategories();
      final byName = {
        for (final category in currentCategories) category.name.toLowerCase(): category,
      };

      for (final seed in requiredCategories) {
        if (!byName.containsKey(seed.name.toLowerCase())) {
          final newId = await _db.insertCategory(
            CategoriesCompanion(
              name: Value(seed.name),
              color: Value(seed.color),
              icon: Value(seed.iconCodePoint),
            ),
          );
          byName[seed.name.toLowerCase()] = Category(
            id: newId,
            name: seed.name,
            color: seed.color,
            icon: seed.iconCodePoint,
          );
        }
      }

      final now = DateTime.now();
      final dummyExpenses = <_ExpenseSeed>[
        const _ExpenseSeed(category: 'cleaning supply', cost: 200, name: 'bleach'),
        const _ExpenseSeed(category: 'TCG', cost: 120, name: 'charizard'),
        const _ExpenseSeed(category: 'cleaning supply', cost: 400, name: 'detergent'),
        const _ExpenseSeed(category: 'clothes', cost: 300, name: ''),
        const _ExpenseSeed(category: 'pet', cost: 300, name: 'Kibble'),
        _ExpenseSeed(
          category: 'furniture',
          cost: 680,
          name: 'desk lamp',
          date: DateTime(2025, 1, 9),
        ),
        _ExpenseSeed(
          category: 'pet',
          cost: 215,
          name: 'vet check',
          date: DateTime(2025, 2, 22),
        ),
        _ExpenseSeed(
          category: 'TCG',
          cost: 95,
          name: 'booster pack',
          date: DateTime(2025, 4, 5),
        ),
        _ExpenseSeed(
          category: 'clothes',
          cost: 180,
          name: 'socks bundle',
          date: DateTime(2025, 7, 14),
        ),
        _ExpenseSeed(
          category: 'cleaning supply',
          cost: 140,
          name: 'mop refill',
          date: DateTime(2025, 11, 3),
        ),
      ];

      for (final expense in dummyExpenses) {
        final category = byName[expense.category.toLowerCase()];
        if (category == null) {
          continue;
        }

        final normalizedName = expense.name.trim();
        await _db.insertExpense(
          ExpensesCompanion(
            name: normalizedName.isEmpty ? const Value.absent() : Value(normalizedName),
            amount: Value(expense.cost),
            date: Value(expense.date ?? now),
            categoryId: Value(category.id),
          ),
        );
      }
    });
  }
}

class _CategorySeed {
  final String name;
  final int color;
  final int iconCodePoint;

  const _CategorySeed(this.name, this.color, this.iconCodePoint);
}

class _ExpenseSeed {
  final String category;
  final double cost;
  final String name;
  final DateTime? date;

  const _ExpenseSeed({
    required this.category,
    required this.cost,
    required this.name,
    this.date,
  });
}
