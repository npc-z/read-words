import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift/wasm.dart' as wasm;
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:read_words/data/app_database.dart';

/// 数据库连接:Android/iOS 走原生 SQLite(drift_flutter);Web 走 WASM(drift)。
///
/// Web 需要 `web/` 目录下的 `sqlite3.wasm` 与 `drift_worker.js`
/// (与 drift 版本匹配的构建产物,见 docs/PRD.md 或 drift 发布页)。
///
/// Web 连接加 20s 超时:drift web 曾出现偶发卡死(上游 issue #3242,
/// SharedWorker 探测/通道初始化不返回),超时把"永久转圈"变成可见错误。
Future<AppDatabase> openDatabase() async {
  final connection = kIsWeb
      ? DatabaseConnection.delayed(Future(() async {
          final result = await wasm.WasmDatabase.open(
            databaseName: 'read_words',
            sqlite3Uri: Uri.parse('sqlite3.wasm'),
            driftWorkerUri: Uri.parse('drift_worker.js'),
          ).timeout(
            const Duration(seconds: 20),
            onTimeout: () {
              throw TimeoutException('数据库打开超时(Web WASM 初始化)');
            },
          );
          return result.resolvedExecutor;
        }))
      : driftDatabase(name: 'read_words');
  return AppDatabase(connection);
}
