import 'dart:async';

import 'package:budget_app/core/database/app_database.dart';
import 'package:budget_app/feature/categories/data/category_data_source.dart';
import 'package:budget_app/feature/categories/domain/category_name.dart';
import 'package:flutter/material.dart';

class CategoriesProvider extends ChangeNotifier {
  final CategoryDataSource _dataSource;
  late final StreamSubscription<List<Category>> _subscription;

  List<Category> _categories = [];
  bool _isLoading = true;

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;

  CategoriesProvider(AppDatabase database)
    : _dataSource = CategoryDataSource(database) {
    _subscription = _dataSource.watchAllCategories().listen((data) {
      _categories = data;
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> addCategory(String name, int color, int icon) async {
    final categoryName = CategoryName.fromRaw(name);
    if (categoryName == null) {
      return;
    }

    final alreadyExists = _categories.any(
      (category) => categoryName.equalsIgnoringCase(category.name),
    );
    if (alreadyExists) {
      return;
    }

    await _dataSource.addCategory(
      name: categoryName.value,
      color: color,
      icon: icon,
    );
  }

  Future<void> deleteCategory(int id) {
    return _dataSource.deleteCategory(id);
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
