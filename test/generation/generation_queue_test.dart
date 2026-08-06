import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:read_words/data/app_database.dart';
import 'package:read_words/data/repositories.dart';
import 'package:read_words/data/settings.dart';
import 'package:read_words/generation/budget.dart';
import 'package:read_words/generation/deepseek_client.dart';
import 'package:read_words/generation/generation_queue.dart';
import 'package:read_words/generation/generation_service.dart';

import 'fake_client.dart';

Future<void> waitFor(
  Future<bool> Function() cond, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!await cond()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('等待条件超时');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late Repositories repo;
  late FakeClient client;
  late GenerationService service;
  late DateTime now;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = Repositories(db);
    client = FakeClient();
    service = GenerationService(client: client, repositories: repo);
    now = DateTime(2026, 8, 6, 10, 30);
  });

  tearDown(() => db.close());

  GenerationQueue queue({BudgetLedger? budget}) => GenerationQueue(
    repositories: repo,
    service: service,
    budget: budget ?? BudgetLedger(repositories: repo, now: () => now),
  );

  Future<int> seedSet(String name, List<String> words) async {
    final setId = await repo.createWordSet(name);
    await repo.addWords(setId, words);
    return setId;
  }

  Future<List<Word>> words(int setId) => repo.wordsInSet(setId);

  Future<int> wordIdOf(int setId, String headword) async {
    return (await words(setId)).firstWhere((w) => w.headword == headword).id;
  }

  group('batch & priority (§6.1)', () {
    test(
      'startBatch enqueues all notGenerated words and consumes to done',
      () async {
        final setId = await seedSet('test', ['a', 'b', 'c']);
        final q = queue();
        await q.startBatch(setId);

        await waitFor(
          () async => (await words(
            setId,
          )).every((w) => w.status == WordStatus.done.name),
        );
        expect(client.callCount, 3);
        expect(await q.pendingCount, 0);
        expect(q.running, isFalse);
      },
    );

    test(
      'immediate task runs before remaining batch words (priority insertion)',
      () async {
        await repo.saveSettings(const AppSettings(concurrency: 2));
        final setId = await seedSet('test', ['a', 'b', 'c', 'd', 'e']);
        final g1 = Completer<void>();
        final g2 = Completer<void>();
        client.gates
          ..add(g1)
          ..add(g2);
        final q = queue();
        final run = q.startBatch(setId); // 不 await:批次在飞

        // 2 个 worker 各占 1 词在飞;c 还在排队
        await waitFor(() async => client.callCount == 2);
        final cId = await wordIdOf(setId, 'c');

        // 批次运行中,点开未生成词 c → 即时生成(优先级提升)
        await q.enqueue(cId, immediate: true);
        g1.complete();
        // c 先于仍在飞的 b 完成(优先级插入生效)
        await waitFor(
          () async =>
              client.completionOrder.contains('c') &&
              !client.completionOrder.contains('b'),
        );
        g2.complete();
        await run;
        await waitFor(() async => await q.pendingCount == 0);
        expect(
          (await words(setId)).every((w) => w.status == WordStatus.done.name),
          isTrue,
        );
      },
    );

    test('enqueue is idempotent for pending words', () async {
      final setId = await seedSet('test', ['a']);
      final q = queue();
      await q.startBatch(setId);
      final aId = await wordIdOf(setId, 'a');

      await q.enqueue(aId);
      await waitFor(() async => await q.pendingCount == 0);
      expect(client.callCount, 1); // 未重复生成
    });

    test('startBatch skips words already pending', () async {
      await repo.saveSettings(const AppSettings(concurrency: 1));
      final setId = await seedSet('test', ['a', 'b']);
      final g1 = Completer<void>();
      client.gates.add(g1);
      final q = queue();
      final run = q.startBatch(setId);
      await waitFor(() async => client.callCount == 1);
      final before = await repo.pendingGenerationTaskCount();

      await q.startBatch(setId); // 再次打开控制台:不重复入队
      expect(await repo.pendingGenerationTaskCount(), before);

      g1.complete();
      await run;
      await waitFor(() async => await q.pendingCount == 0);
      expect(client.callCount, 2);
    });
  });

  group('budget (§6.2): 只约束后台任务', () {
    test('batch stops at limit, immediate generation bypasses', () async {
      await repo.saveSettings(
        const AppSettings(dailyReadingX: 1, budgetMultiple: 1),
      );
      final setId = await seedSet('test', ['a', 'b']);
      final q = queue();
      await q.startBatch(setId);

      await waitFor(() async => q.budgetExhausted);
      expect(client.callCount, 1);
      final ws = await words(setId);
      expect(ws[0].status, WordStatus.done.name);
      expect(ws[1].status, WordStatus.queued.name);
      expect(await repo.budgetUsedOn(BudgetLedger.dayOf(now)), 1);

      // 即时生成不受预算限制
      final bId = ws[1].id;
      await q.enqueue(bId, immediate: true);
      await waitFor(() async => await q.pendingCount == 0);
      expect((await words(setId))[1].status, WordStatus.done.name);
      expect(await repo.budgetUsedOn(BudgetLedger.dayOf(now)), 1); // 后台额度未变
    });

    test('continue background after day rollover resumes', () async {
      await repo.saveSettings(
        const AppSettings(dailyReadingX: 1, budgetMultiple: 1),
      );
      final setId = await seedSet('test', ['a', 'b']);
      final q = queue();
      await q.startBatch(setId);
      await waitFor(() async => q.budgetExhausted);
      expect(client.callCount, 1);

      await q.continueBackground(); // 同日:no-op
      expect(client.callCount, 1);

      now = DateTime(2026, 8, 7, 8, 0);
      await q.continueBackground();
      await waitFor(() async => await q.pendingCount == 0);
      expect(client.callCount, 2);
      expect(q.budgetExhausted, isFalse);
    });

    test(
      'failed words do not consume budget and do not block the batch',
      () async {
        await repo.saveSettings(
          const AppSettings(dailyReadingX: 1, budgetMultiple: 1),
        );
        client.errorToThrow = const GenerationApiException(
          GenerationErrorKind.permanent,
          'API 错误 401',
        );
        final setId = await seedSet('test', ['a', 'b']);
        final q = queue();
        await q.startBatch(setId);

        await waitFor(() async => await q.pendingCount == 0);
        expect(client.callCount, 2);
        expect(q.budgetExhausted, isFalse);
        expect((await repo.budgetUsedOn(BudgetLedger.dayOf(now))), 0);
      },
    );
  });

  group('pause / cancel / retry (§6)', () {
    test('pause stops dispatch, in-flight settle, resume continues', () async {
      final setId = await seedSet('test', ['a', 'b', 'c', 'd']);
      final g1 = Completer<void>();
      final g2 = Completer<void>();
      client.gates
        ..add(g1)
        ..add(g2);
      await repo.saveSettings(const AppSettings(concurrency: 2));
      final q = queue();
      unawaited(q.startBatch(setId));
      await waitFor(() async => client.callCount == 2);

      await q.pause();
      expect(q.paused, isTrue);
      g1.complete();
      g2.complete();
      await waitFor(
        () async => (await words(
          setId,
        )).take(2).every((w) => w.status == WordStatus.done.name),
      );
      final ws = await words(setId);
      expect(ws[0].status, WordStatus.done.name);
      expect(ws[1].status, WordStatus.done.name);
      expect(ws[2].status, WordStatus.queued.name);
      expect(ws[3].status, WordStatus.queued.name);

      await q.resume();
      await waitFor(() async => await q.pendingCount == 0);
      expect(
        (await words(setId)).every((w) => w.status == WordStatus.done.name),
        isTrue,
      );
    });

    test(
      'cancelWordSet resets its queued words, other sets unaffected',
      () async {
        await repo.saveSettings(const AppSettings(concurrency: 2));
        final setIdA = await seedSet('A', ['a', 'b', 'c']);
        final setIdB = await seedSet('B', ['x', 'y']);
        final g1 = Completer<void>();
        final g2 = Completer<void>();
        client.gates
          ..add(g1)
          ..add(g2);
        final q = queue();
        unawaited(q.startBatch(setIdA));
        await waitFor(() async => client.callCount == 2); // a、b 在飞
        await q.startBatch(setIdB); // 并发批次:队列合并

        await q.cancelWordSet(setIdA);
        g1.complete();
        g2.complete();
        await waitFor(
          () async => (await words(
            setIdA,
          )).take(2).every((w) => w.status == WordStatus.done.name),
        );
        await waitFor(() async => await q.pendingCount == 0);

        final wsA = await words(setIdA);
        expect(wsA[0].status, WordStatus.done.name); // 在飞词结算保留
        expect(wsA[1].status, WordStatus.done.name);
        expect(wsA[2].status, WordStatus.notGenerated.name); // 排队词回未生成
        // B 词集不受影响
        expect(
          (await words(setIdB)).every((w) => w.status == WordStatus.done.name),
          isTrue,
        );
      },
    );

    test('retry re-enqueues a failed word', () async {
      client.errorToThrow = const GenerationApiException(
        GenerationErrorKind.permanent,
        '临时失败',
      );
      final setId = await seedSet('test', ['a']);
      final q = queue();
      await q.startBatch(setId);
      await waitFor(() async => await q.pendingCount == 0);
      expect(q.errors, hasLength(1));

      client.errorToThrow = null;
      final aId = await wordIdOf(setId, 'a');
      await q.retry(aId);
      await waitFor(() async => await q.pendingCount == 0);
      expect((await words(setId)).single.status, WordStatus.done.name);
      expect(client.callCount, 2);
    });

    test('retry is refused while budget exhausted', () async {
      await repo.saveSettings(
        const AppSettings(dailyReadingX: 1, budgetMultiple: 1),
      );
      client.errorToThrow = const GenerationApiException(
        GenerationErrorKind.permanent,
        '临时失败',
      );
      final setId = await seedSet('test', ['a']);
      final q = queue();
      await q.startBatch(setId);
      await waitFor(() async => await q.pendingCount == 0);
      expect((await words(setId)).single.status, WordStatus.failed.name);

      await repo.addBudgetUse(BudgetLedger.dayOf(now), 1); // 今日已用满
      client.errorToThrow = null;
      await q.retry((await words(setId)).single.id);
      expect(client.callCount, 1); // 达限不重试
      expect((await words(setId)).single.status, WordStatus.failed.name);
    });
  });

  group('restart resume (§6.1)', () {
    test(
      'pending tasks resume after restart (interrupted generating retried)',
      () async {
        final dir = Directory.systemTemp.createTempSync('rw-queue');
        final file = File('${dir.path}/test.db');
        try {
          final db1 = AppDatabase(NativeDatabase(file));
          final repo1 = Repositories(db1);
          final setId = await repo1.createWordSet('test');
          await repo1.addWords(setId, ['a', 'b']);
          await repo1.saveSettings(const AppSettings(concurrency: 1));

          final g1 = Completer<void>();
          final client1 = FakeClient(gate: g1);
          final q1 = GenerationQueue(
            repositories: repo1,
            service: GenerationService(client: client1, repositories: repo1),
          );
          // 崩溃模拟:批次跑一半,a 停在 generating,b 排队
          unawaited(q1.startBatch(setId));
          await waitFor(() async => client1.callCount == 1);
          final ws1 = await repo1.wordsInSet(setId);
          expect(ws1[0].status, WordStatus.generating.name);
          expect(ws1[1].status, WordStatus.queued.name);

          // 重启:新连接 + resumePending
          final db2 = AppDatabase(NativeDatabase(file));
          final repo2 = Repositories(db2);
          final client2 = FakeClient();
          final q2 = GenerationQueue(
            repositories: repo2,
            service: GenerationService(client: client2, repositories: repo2),
          );
          await q2.resumePending();
          await waitFor(() async {
            final ws = await repo2.wordsInSet(setId);
            return ws.every((w) => w.status == WordStatus.done.name);
          });

          // 中断词被重试,两个词都完成
          expect(client2.callOrder, hasLength(2));
          final ws = await repo2.wordsInSet(setId);
          expect(ws.every((w) => w.status == WordStatus.done.name), isTrue);

          // 收尾:放行 q1 的挂起 worker,等其完全空闲后再关库
          g1.complete();
          await waitFor(() async => !q1.running);
          await Future<void>.delayed(const Duration(milliseconds: 50));
          await db1.close();
          await db2.close();
        } finally {
          dir.deleteSync(recursive: true);
        }
      },
    );
  });
}
