import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:read_words/data/app_database.dart';
import 'package:read_words/data/repositories.dart';
import 'package:read_words/data/settings.dart';
import 'package:read_words/generation/budget.dart';

void main() {
  // 重启保留测试顺序重开同一文件 DB,误报可静默
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late Repositories repo;
  late DateTime now;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = Repositories(db);
    now = DateTime(2026, 8, 6, 10, 30);
  });

  tearDown(() => db.close());

  BudgetLedger ledger() => BudgetLedger(repositories: repo, now: () => now);

  test('limit = dailyReadingX × budgetMultiple from settings', () async {
    expect((await ledger().state()).limit, 150); // 默认 50 × 3

    await repo.saveSettings(const AppSettings(dailyReadingX: 5, budgetMultiple: 4));
    expect((await ledger().state()).limit, 20);
  });

  test('used starts at 0 and accumulates records on the same day', () async {
    final l = ledger();
    expect((await l.state()).used, 0);

    await l.record(2);
    await l.record(3);
    final s = await l.state();
    expect(s.used, 5);
    expect(s.exhausted, isFalse);
  });

  test('exhausted when used reaches limit', () async {
    await repo.saveSettings(const AppSettings(dailyReadingX: 2, budgetMultiple: 2));
    final l = ledger();
    await l.record(3);
    expect((await l.state()).exhausted, isFalse);

    await l.record(1);
    final s = await l.state();
    expect(s.used, 4);
    expect(s.exhausted, isTrue);
  });

  test('natural day rollover resets used (local timezone)', () async {
    await repo.saveSettings(const AppSettings(dailyReadingX: 1, budgetMultiple: 1));
    final l = ledger();
    await l.record(1);
    expect((await l.state()).exhausted, isTrue);

    // 次日(本地时区)重置
    now = DateTime(2026, 8, 7, 0, 0);
    final s = await l.state();
    expect(s.used, 0);
    expect(s.exhausted, isFalse);
  });

  test('records persist across restart (file reopen)', () async {
    final dir = Directory.systemTemp.createTempSync('rw-budget');
    final file = File('${dir.path}/test.db');
    try {
      final db1 = AppDatabase(NativeDatabase(file));
      final repo1 = Repositories(db1);
      await BudgetLedger(repositories: repo1, now: () => now).record(4);
      await db1.close();

      final db2 = AppDatabase(NativeDatabase(file));
      final repo2 = Repositories(db2);
      final s = await BudgetLedger(repositories: repo2, now: () => now).state();
      expect(s.used, 4);
      expect(s.limit, 150);
      await db2.close();
    } finally {
      dir.deleteSync(recursive: true);
    }
  });
}
