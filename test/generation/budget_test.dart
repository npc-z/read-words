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

  test('reserve succeeds until limit, then fails (hard cap)', () async {
    await repo.saveSettings(const AppSettings(dailyReadingX: 2, budgetMultiple: 2));
    final l = ledger();
    expect((await l.state()).used, 0);

    for (var i = 0; i < 4; i++) {
      expect(await l.reserve(), isTrue);
    }
    expect((await l.state()).used, 4);
    expect((await l.state()).exhausted, isTrue);

    expect(await l.reserve(), isFalse);
    expect((await l.state()).used, 4); // 超限预约不记账
  });

  test('release frees a slot and never goes below zero', () async {
    await repo.saveSettings(const AppSettings(dailyReadingX: 2, budgetMultiple: 2));
    final l = ledger();
    await l.reserve();
    await l.reserve();

    await l.release();
    final s = await l.state();
    expect(s.used, 1);
    expect(await l.reserve(), isTrue); // 释放后可再预约

    await l.release();
    await l.release();
    expect((await l.state()).used, 0);
  });

  test('natural day rollover resets used (local timezone)', () async {
    await repo.saveSettings(const AppSettings(dailyReadingX: 1, budgetMultiple: 1));
    final l = ledger();
    await l.reserve();
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
      await repo1.addBudgetUse(BudgetLedger.dayOf(now), 4);
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
