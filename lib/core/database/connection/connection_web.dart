import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

QueryExecutor openConnectionImpl() {
  return LazyDatabase(() async {
    final result = await WasmDatabase.open(
      databaseName: 'budget_app_db',
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.dart.js'),
    );

    return result.resolvedExecutor.executor;
  });
}
