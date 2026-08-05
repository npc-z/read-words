import 'package:drift_flutter/drift_flutter.dart';
import 'package:read_words/data/app_database.dart';

/// 数据库连接:Android/iOS 走原生 SQLite;Web 走 WASM(drift_flutter)。
Future<AppDatabase> openDatabase() async {
  final db = AppDatabase(driftDatabase(name: 'read_words'));
  return db;
}
