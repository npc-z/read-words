import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:read_words/data/app_database.dart';
import 'package:read_words/data/repositories.dart';
import 'package:read_words/data/settings.dart';

void main() {
  // 重启保留测试顺序重开同一文件 DB,第一个已 close,误报可静默
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late Repositories repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = Repositories(db);
  });

  tearDown(() => db.close());

  group('Settings defaults', () {
    test('settings() returns defaults when nothing stored', () async {
      final s = await repo.settings();
      expect(s.level, EnglishLevel.gaokao);
      expect(s.dailyReadingX, 50);
      expect(s.budgetMultiple, 3);
      expect(s.concurrency, 4);
      expect(s.apiKey, '');
      expect(s.defaultViewMode, ViewMode.study);
      expect(s.displayMode, DisplayMode.both);
    });

    test('partially stored keys fall back to defaults per key', () async {
      await repo.setSetting(SettingsKeys.dailyReadingX, '30');
      await repo.setSetting(SettingsKeys.apiKey, 'sk-test');

      final s = await repo.settings();
      expect(s.dailyReadingX, 30);
      expect(s.apiKey, 'sk-test');
      expect(s.budgetMultiple, 3);
      expect(s.level, EnglishLevel.gaokao);
    });

    test('corrupted stored values fall back to defaults', () async {
      await repo.setSetting(SettingsKeys.concurrency, 'not-a-number');
      await repo.setSetting(SettingsKeys.level, 'no-such-level');

      final s = await repo.settings();
      expect(s.concurrency, 4);
      expect(s.level, EnglishLevel.gaokao);
    });
  });

  group('Settings round trip', () {
    test('saveSettings round trips all keys', () async {
      const desired = AppSettings(
        level: EnglishLevel.tem48,
        dailyReadingX: 30,
        budgetMultiple: 2,
        concurrency: 8,
        apiKey: 'sk-123',
        defaultViewMode: ViewMode.review,
        displayMode: DisplayMode.en,
      );
      await repo.saveSettings(desired);

      final s = await repo.settings();
      expect(s.level, EnglishLevel.tem48);
      expect(s.dailyReadingX, 30);
      expect(s.budgetMultiple, 2);
      expect(s.concurrency, 8);
      expect(s.apiKey, 'sk-123');
      expect(s.defaultViewMode, ViewMode.review);
      expect(s.displayMode, DisplayMode.en);
    });

    test('settings survive restart (persist across reopen)', () async {
      final dir = Directory.systemTemp.createTempSync('rw-settings');
      final file = File('${dir.path}/test.db');
      try {
        final db1 = AppDatabase(NativeDatabase(file));
        await Repositories(db1).saveSettings(
          const AppSettings(
            level: EnglishLevel.cet46,
            dailyReadingX: 20,
            budgetMultiple: 5,
            concurrency: 2,
            apiKey: 'sk-restart',
            defaultViewMode: ViewMode.lookup,
            displayMode: DisplayMode.zh,
          ),
        );
        await db1.close();

        final db2 = AppDatabase(NativeDatabase(file));
        final s = await Repositories(db2).settings();
        expect(s.apiKey, 'sk-restart');
        expect(s.level, EnglishLevel.cet46);
        expect(s.dailyReadingX, 20);
        expect(s.displayMode, DisplayMode.zh);
        await db2.close();
      } finally {
        dir.deleteSync(recursive: true);
      }
    });
  });
}
