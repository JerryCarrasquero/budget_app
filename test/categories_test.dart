import 'package:budget_app/core/database/app_database.dart';
import 'package:budget_app/feature/categories/provider/categories_provider.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Categories', () {
    test('getAllCategories returns inserted categories with full model fields', () async {
      final db = AppDatabase(NativeDatabase.memory());

      await db.insertCategory(
        CategoriesCompanion.insert(
          name: 'Food',
          color: const Value(0xFF112233),
          icon: const Value(0xe532),
        ),
      );
      await db.insertCategory(
        CategoriesCompanion.insert(
          name: 'Transport',
          color: const Value(0xFF445566),
          icon: const Value(0xe571),
        ),
      );

      final categories = await db.getAllCategories();
      final food = categories.firstWhere((c) => c.name == 'Food');
      final transport = categories.firstWhere((c) => c.name == 'Transport');

      expect(food.name, 'Food');
      expect(food.color, 0xFF112233);
      expect(food.icon, 0xe532);

      expect(transport.name, 'Transport');
      expect(transport.color, 0xFF445566);
      expect(transport.icon, 0xe571);

      await db.close();
    });

    test('CategoriesProvider adds category', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final provider = CategoriesProvider(db);

      await provider.addCategory('Pet', 0xFF00AA00, 0xe91d);
      final categories = await db.getAllCategories();
      final pet = categories.firstWhere((c) => c.name == 'Pet');

      expect(pet.name, 'Pet');
      expect(pet.color, 0xFF00AA00);
      expect(pet.icon, 0xe91d);

      provider.dispose();
      await db.close();
    });

    test('CategoriesProvider sanitizes names and prevents duplicates', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final provider = CategoriesProvider(db);

      await provider.addCategory('  F@@oo###d  ', 0xFF123456, 0xe532);
      await provider.addCategory('food', 0xFF654321, 0xe571);

      final categories = await db.getAllCategories();
      final food = categories.where((c) => c.name == 'Food').toList();

      expect(food.length, 1);

      provider.dispose();
      await db.close();
    });
  });
}
