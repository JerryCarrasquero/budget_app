import 'package:budget_app/core/utils/input_sanitizer.dart';

class CategoryName {
  final String value;

  const CategoryName._(this.value);

  static CategoryName? fromRaw(String rawName) {
    final normalizedName = InputSanitizer.sanitizeCategoryName(rawName);
    if (normalizedName.isEmpty) {
      return null;
    }
    return CategoryName._(normalizedName);
  }

  bool equalsIgnoringCase(String other) {
    return value.toLowerCase() == other.toLowerCase();
  }
}
