import 'package:budget_app/core/database/app_database.dart';
import 'package:budget_app/core/text/app_text_provider.dart';
import 'package:flutter/material.dart';
import 'package:budget_app/feature/home/presentation/screen/home_page.dart';
import 'package:provider/provider.dart';

class App extends StatelessWidget {
  const App({super.key, required this.database});

  final AppDatabase database;

  @override
  Widget build(BuildContext context) {
    const textProvider = AppTextProvider();

    return MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: database),
        Provider<AppTextProvider>.value(value: textProvider),
      ],
      child: MaterialApp(
        title: textProvider.appTitle,
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const HomePage(),
      ),
    );
  }
}
