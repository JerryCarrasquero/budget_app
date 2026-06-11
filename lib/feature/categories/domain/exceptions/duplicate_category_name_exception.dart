class DuplicateCategoryNameException implements Exception {
  final String name;

  const DuplicateCategoryNameException(this.name);
}
