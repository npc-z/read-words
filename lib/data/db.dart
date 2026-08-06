import 'package:drift_flutter/drift_flutter.dart';
import 'package:read_words/data/app_database.dart';

/// 数据库连接:Android/iOS 走原生 SQLite;Web 走 WASM(drift_flutter)。
///
/// Web 需要 `web/` 目录下的 `sqlite3.wasm` 与 `drift_worker.js`
/// (与 drift 版本匹配的构建产物,见 docs/PRD.md 或 drift 发布页)。
Future<AppDatabase> openDatabase() async {
  final db = AppDatabase(
    driftDatabase(
      name: 'read_words',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    ),
  );
  return db;
}
