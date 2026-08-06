import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:read_words/data/app_database.dart';
import 'package:read_words/data/repositories.dart';
import 'package:read_words/data/settings.dart';
import 'package:read_words/generation/budget.dart';
import 'package:read_words/generation/deepseek_client.dart';
import 'package:read_words/generation/generation_service.dart';
import 'package:read_words/generation/task_controller.dart';

import 'fake_client.dart';

void main() {
  late AppDatabase db;
  late Repositories repo;
  late FakeClient client;
  late GenerationService service;
  late int setId;
  late DateTime now;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = Repositories(db);
    client = FakeClient();
    service = GenerationService(client: client, repositories: repo);
    now = DateTime(2026, 8, 6, 10, 30);
  });

  tearDown(() => db.close());

  BudgetLedger ledger() => BudgetLedger(repositories: repo, now: () => now);

  Future<GenerationTaskController> controller({BudgetLedger? budget}) async {
    return GenerationTaskController(
      wordSetId: setId,
      repositories: repo,
      service: service,
      budget: budget ?? ledger(),
    );
  }

  Future<void> seed(List<String> words) async {
    setId = await repo.createWordSet('test');
    await repo.addWords(setId, words);
  }

  Future<List<Word>> words() => repo.wordsInSet(setId);

  test('batch stops at budget limit, remaining words stay queued', () async {
    await repo.saveSettings(const AppSettings(dailyReadingX: 1, budgetMultiple: 1));
    await seed(['run', 'walk', 'jump']);
    final c = await controller();
    await c.start();

    expect(client.callCount, 1);
    expect(c.budgetExhausted, isTrue);
    expect(c.successCount, 1);
    expect(c.failureCount, 0);
    expect(c.pendingCount, 2);

    final ws = await words();
    expect(ws[0].status, WordStatus.done.name);
    expect(ws[1].status, WordStatus.queued.name);
    expect(ws[2].status, WordStatus.queued.name);
    expect(c.tasks[0].status, WordStatus.done);
    expect(c.tasks[1].status, WordStatus.queued);
  });

  test('continue batch after natural day rollover resumes remaining', () async {
    await repo.saveSettings(const AppSettings(dailyReadingX: 2, budgetMultiple: 1));
    await seed(['run', 'walk', 'jump']);
    final c = await controller();
    await c.start();

    expect(client.callCount, 2);
    expect(c.budgetExhausted, isTrue);

    now = DateTime(2026, 8, 7, 8, 0); // 次日
    await c.continueBatch();

    expect(c.budgetExhausted, isFalse);
    expect(client.callCount, 3);
    expect(c.successCount, 3);
    expect(c.pendingCount, 0);
    final ws = await words();
    expect(ws.every((w) => w.status == WordStatus.done.name), isTrue);
  });

  test('continue batch on the same day is a no-op', () async {
    await repo.saveSettings(const AppSettings(dailyReadingX: 2, budgetMultiple: 1));
    await seed(['run', 'walk', 'jump']);
    final c = await controller();
    await c.start();
    expect(c.budgetExhausted, isTrue);
    expect(client.callCount, 2);

    await c.continueBatch(); // 同日:仍达限

    expect(c.budgetExhausted, isTrue);
    expect(client.callCount, 2);
  });

  test('start when budget already exhausted generates nothing', () async {
    await repo.saveSettings(const AppSettings(dailyReadingX: 1, budgetMultiple: 1));
    await repo.addBudgetUse(BudgetLedger.dayOf(now), 1);
    await seed(['run', 'walk']);
    final c = await controller();
    await c.start();

    expect(client.callCount, 0);
    expect(c.budgetExhausted, isTrue);
    expect(c.pendingCount, 2);
    final ws = await words();
    expect(ws.every((w) => w.status == WordStatus.queued.name), isTrue);
  });

  test('failed words do not consume budget and do not block the batch', () async {
    await repo.saveSettings(const AppSettings(dailyReadingX: 1, budgetMultiple: 1));
    client.errorToThrow = const GenerationApiException(
      GenerationErrorKind.permanent,
      'API 错误 401',
    );
    await seed(['run', 'walk']);
    final c = await controller();
    await c.start();

    // 全部失败:预算未被消耗,批次跑完而非达限暂停
    expect(client.callCount, 2);
    expect(c.failureCount, 2);
    expect(c.budgetExhausted, isFalse);
    expect((await ledger().state()).used, 0);
  });

  test('immediate generation is not budget-constrained', () async {
    await repo.saveSettings(const AppSettings(dailyReadingX: 1, budgetMultiple: 1));
    await repo.addBudgetUse(BudgetLedger.dayOf(now), 1); // 已达限
    await seed(['run']);

    // 点开未生成词的即时生成:直接调用 generateWord,不经预算账本
    final word = (await words()).single;
    final outcome = await service.generateWord(word.id);

    expect(outcome.failed, isFalse);
    expect(client.callCount, 1);
    expect((await words()).single.status, WordStatus.done.name);
  });
}
