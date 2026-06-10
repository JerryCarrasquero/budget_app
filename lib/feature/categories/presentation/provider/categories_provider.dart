import 'dart:async';

import 'package:budget_app/core/database/app_database.dart';
import 'package:budget_app/core/utils/input_sanitizer.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';

class CategoriesProvider extends ChangeNotifier {
  final AppDatabase _database;
  late final StreamSubscription<List<Category>> _subscription;

  List<Category> _categories = [];
  bool _isLoading = true;

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;

  CategoriesProvider(this._database) {
    _subscription = _database.watchAllCategories().listen((data) {
      _categories = data;
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> addCategory(String name, int color, int icon) async {
    final normalizedName = InputSanitizer.sanitizeCategoryName(name);
    if (normalizedName.isEmpty) {
      return;
    }

    final alreadyExists = _categories.any(
      (category) => category.name.toLowerCase() == normalizedName.toLowerCase(),
    );
    if (alreadyExists) {
      return;
    }

    await _database.insertCategory(
      CategoriesCompanion(
        name: drift.Value(normalizedName),
        color: drift.Value(color),
        icon: drift.Value(icon),
      ),
    );
  }

  Future<void> deleteCategory(int id) {
    return _database.deleteCategory(id);
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
