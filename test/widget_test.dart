import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:read_words/data/app_database.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

void main() {
  test('database schema opens at v2', () async {
    final db = AppDatabase(NativeDatabase.memory());
    await db.customSelect('SELECT 1 FROM sqlite_master LIMIT 1').get();
    expect(db.schemaVersion, 2);
    await db.close();
  });

  test('fresh v2 database: settings table has key primary key', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final tableInfo = await db
        .customSelect('PRAGMA table_info(settings_table)')
        .get();
    final pk = tableInfo
        .where((r) => r.data['pk'] == 1)
        .map((r) => r.data['name'])
        .toList();
    expect(pk, ['key']);
    await db.close();
  });

  test('migrates v1 database: settings table rebuilt with primary key', () async {
    final dir = await Directory.systemTemp.createTemp('drift-migrate');
    final file = File('${dir.path}/migrate_test.db');
    final raw = sqlite3.sqlite3.open(file.path);
    raw.execute(
      'CREATE TABLE settings_table ("key" TEXT NOT NULL, "value" TEXT NOT NULL);',
    );
    raw.execute('PRAGMA user_version = 1;');
    raw.close();

    final db = AppDatabase(NativeDatabase(file));
    await db.customSelect('SELECT 1 FROM settings_table LIMIT 1').get();

    final tableInfo = await db
        .customSelect('PRAGMA table_info(settings_table)')
        .get();
    final pk = tableInfo
        .where((r) => r.data['pk'] == 1)
        .map((r) => r.data['name'])
        .toList();
    expect(pk, ['key']);
    expect(db.schemaVersion, 2);
    await db.close();
    file.deleteSync();
    dir.deleteSync();
  });
}
