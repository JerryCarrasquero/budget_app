class InputSanitizer {
  static String _collapseWhitespace(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String sanitizeCategoryName(String input) {
    final alphanumeric = input.replaceAll(RegExp(r'[^A-Za-z0-9\s]'), '');
    return _collapseWhitespace(alphanumeric);
  }

  static String? sanitizeExpenseName(String? input) {
    if (input == null) {
      return null;
    }

    final alphanumeric = input.replaceAll(RegExp(r'[^A-Za-z0-9\s]'), '');
    final normalized = _collapseWhitespace(alphanumeric);
    return normalized.isEmpty ? null : normalized;
  }

  static double? parseAmount(String input) {
    final digitsAndDot = input.replaceAll(RegExp(r'[^0-9.]'), '');
    if (digitsAndDot.isEmpty) {
      return null;
    }

    final firstDotIndex = digitsAndDot.indexOf('.');
    String normalized = digitsAndDot;
    if (firstDotIndex != -1) {
      final integerPart = digitsAndDot.substring(0, firstDotIndex + 1);
      final rawDecimalPart = digitsAndDot
          .substring(firstDotIndex + 1)
          .replaceAll('.', '');
      final decimalPart = rawDecimalPart.length <= 2
          ? rawDecimalPart
          : rawDecimalPart.substring(0, 2);
      normalized = integerPart + decimalPart;
    }

    final parsed = double.tryParse(normalized);
    if (parsed == null || parsed <= 0) {
      return null;
    }

    return double.parse(parsed.toStringAsFixed(2));
  }
}
