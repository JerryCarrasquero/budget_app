import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';

import 'package:budget_app/core/database/app_database.dart';
import 'package:budget_app/core/text/app_texts.dart';
import 'package:budget_app/app.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester, AppDatabase database) async {
    await tester.pumpWidget(App(database: database));
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('Home page smoke test', (WidgetTester tester) async {
    final database = AppDatabase(NativeDatabase.memory());
    await pumpApp(tester, database);

    expect(find.text(AppTexts.appTitle), findsOneWidget);
    expect(find.text(AppTexts.currentMonth), findsOneWidget);
    expect(find.text(AppTexts.expenses), findsOneWidget);

    await database.close();
  });

  testWidgets('Open and close Add Expense dialog from expenses section', (
    WidgetTester tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    await pumpApp(tester, database);

    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();

    expect(find.text(AppTexts.addExpenseTitle), findsOneWidget);

    await tester.tap(find.text(AppTexts.cancel));
    await tester.pumpAndSettle();

    expect(find.text(AppTexts.addExpenseTitle), findsNothing);

    await database.close();
  });

  testWidgets('Open and close Add Category dialog from categories page', (
    WidgetTester tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    await pumpApp(tester, database);

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppTexts.categories));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text(AppTexts.addCategoryTitle), findsOneWidget);

    await tester.tap(find.text(AppTexts.cancel));
    await tester.pumpAndSettle();

    expect(find.text(AppTexts.addCategoryTitle), findsNothing);

    await database.close();
  });
}
