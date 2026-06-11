class AppTexts {
  static const String appTitle = 'Budget App';

  static const String menuTitle = 'Menu';
  static const String categories = 'Categories';
  static const String recurringExpenses = 'Recurring Expenses';
  static const String statistics = 'Statistics';

  static const String currentMonth = 'Current Month:';
  static const String totalSpent = 'Total Spent';
  static const String expenses = 'Expenses';
  static const String noWheelData = 'No data for wheel chart yet';
  static const String expenseDetailsTitle = 'Expense Details';
  static const String expenseAmountLabel = 'Amount';
  static const String expenseCategoryLabel = 'Category';
  static const String expenseDateLabel = 'Date';
  static const String close = 'Close';
  static const String addExpenseTitle = 'Add Expense';
  static const String addExpenseNameHint = 'Expense name (optional)';
  static const String addExpenseAmountHint = 'Amount';
  static const String addExpenseCategoryHint = 'Select category';

  static const String addCategoryTitle = 'Add Category';
  static const String addCategoryHint = 'e.g. Food, Transport, Rent';
  static const String categoryNameRequired = 'Category name is required.';
  static const String categoryNameInvalid =
      'Use only letters, numbers, and spaces.';
  static const String categoryNameDuplicate = 'Category name already exists.';
  static const String categorySaveFailed =
      'Could not save category. Please try again.';
  static const String cancel = 'Cancel';
  static const String save = 'Save';
  static const String noCategoriesYet =
      'No categories yet. Add your first one.';

  static const String uncategorizedCategoryName = 'Uncategorize expenses';

  static const List<String> monthNames = [
    '',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static String unnamedCategoryExpense(String category) =>
      'Unnamed $category Expense';

  static String categoryTotalLabel(String category, double total) =>
      '$category: ${total.toStringAsFixed(2)}';

  static String wheelLegendLabel(String category, double total) =>
      '$category (${total.toStringAsFixed(0)})';
}
