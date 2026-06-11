import 'package:flutter/material.dart';
import 'package:budget_app/core/database/app_database.dart';
import 'package:budget_app/core/dev/demo_seeder.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = AppDatabase();
  const bool runningUnderTest = bool.fromEnvironment(
    'FLUTTER_TEST',
    defaultValue: false,
  );
  if (!runningUnderTest) {
    await runDemoSeedSetupIfEnabled(db);
  }
  runApp(App(database: db));
}
