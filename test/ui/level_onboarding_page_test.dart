import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:read_words/data/app_database.dart';
import 'package:read_words/data/repositories.dart';
import 'package:read_words/data/settings.dart';
import 'package:read_words/generation/generation_queue.dart';
import 'package:read_words/generation/generation_service.dart';
import 'package:read_words/ui/first_launch_gate.dart';

import '../generation/fake_client.dart';

void main() {
  late AppDatabase db;
  late Repositories repo;
  late GenerationQueue queue;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = Repositories(db);
    queue = GenerationQueue(
      repositories: repo,
      service: GenerationService(client: FakeClient(), repositories: repo),
    );
  });

  tearDown(() => db.close());

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FirstLaunchGate(repositories: repo, queue: queue),
      ),
    );
    await tester.pumpAndSettle();
  }

  test(
    'hasLevel is false when nothing stored, true after level saved',
    () async {
      expect(await repo.hasLevel(), isFalse);

      await repo.saveSettings(const AppSettings(level: EnglishLevel.cet46));
      expect(await repo.hasLevel(), isTrue);
    },
  );

  test('hasLevel is false when stored level value is invalid', () async {
    await repo.setSetting('level', 'doctorate');
    expect(await repo.hasLevel(), isFalse);
  });

  testWidgets(
    'first launch: mandatory onboarding, selection persists and enters main UI',
    (tester) async {
      await pumpApp(tester);

      expect(find.text('欢迎使用阅读学单词'), findsOneWidget);
      expect(find.text('高考'), findsOneWidget);
      expect(find.text('四六级'), findsOneWidget);
      expect(find.text('专四专八'), findsOneWidget);
      expect(find.text('我的词集'), findsNothing);
      // 不可跳过:没有跳过按钮
      expect(find.text('跳过'), findsNothing);

      await tester.tap(find.text('四六级'));
      await tester.pumpAndSettle();

      expect((await repo.settings()).level, EnglishLevel.cet46);
      expect(find.text('我的词集'), findsOneWidget);
      expect(find.text('欢迎使用阅读学单词'), findsNothing);
    },
  );

  testWidgets('closing app without choosing re-shows onboarding next launch', (
    tester,
  ) async {
    await pumpApp(tester);

    // 不选择直接退出:不产生默认值
    expect(await repo.hasLevel(), isFalse);

    // 模拟下次启动:引导仍应出现
    await tester.pumpWidget(const SizedBox());
    await pumpApp(tester);
    expect(find.text('欢迎使用阅读学单词'), findsOneWidget);
    expect(find.text('我的词集'), findsNothing);
  });

  testWidgets('corrupted stored level falls back to onboarding, no default', (
    tester,
  ) async {
    await repo.setSetting('level', 'doctorate');
    await pumpApp(tester);

    expect(find.text('欢迎使用阅读学单词'), findsOneWidget);
    expect((await repo.settings()).level, EnglishLevel.gaokao);
  });

  testWidgets('non-first launch: main UI directly, no onboarding', (
    tester,
  ) async {
    await repo.saveSettings(const AppSettings(level: EnglishLevel.gaokao));
    await pumpApp(tester);

    expect(find.text('我的词集'), findsOneWidget);
    expect(find.text('欢迎使用阅读学单词'), findsNothing);
  });
}
