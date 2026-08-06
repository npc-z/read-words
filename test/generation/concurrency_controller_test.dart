import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:read_words/data/app_database.dart';
import 'package:read_words/data/repositories.dart';
import 'package:read_words/data/settings.dart';
import 'package:read_words/generation/deepseek_client.dart';
import 'package:read_words/generation/generation_service.dart';
import 'package:read_words/generation/task_controller.dart';

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
  late AppDatabase db;
  late Repositories repo;
  late FakeClient client;
  late GenerationService service;
  late int setId;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = Repositories(db);
    client = FakeClient();
    service = GenerationService(client: client, repositories: repo);
  });

  tearDown(() => db.close());

  Future<GenerationTaskController> controller() async {
    return GenerationTaskController(
      wordSetId: setId,
      repositories: repo,
      service: service,
    );
  }

  Future<void> seed(List<String> words) async {
    setId = await repo.createWordSet('test');
    await repo.addWords(setId, words);
  }

  Future<List<Word>> words() => repo.wordsInSet(setId);

  test('default concurrency is 4, dispatch caps at worker count', () async {
    final g1 = Completer<void>();
    final g2 = Completer<void>();
    final g3 = Completer<void>();
    final g4 = Completer<void>();
    client.gates
      ..add(g1)
      ..add(g2)
      ..add(g3)
      ..add(g4);
    await seed(['a', 'b', 'c', 'd', 'e']); // 5 词
    final c = await controller();

    final batch = c.start();
    await waitFor(() async =>
        (await words()).where((w) => w.status == WordStatus.generating.name).length == 4);

    // 默认并发 4:4 个 worker 各占 1 词在飞,第 5 个未消费
    expect(c.pendingCount, 5);
    final ws = await words();
    expect(ws.take(4).every((w) => w.status == WordStatus.generating.name), isTrue);
    expect(ws[4].status, WordStatus.queued.name);

    for (final g in [g1, g2, g3, g4]) {
      g.complete();
    }
    await batch;
    expect(c.successCount, 5);
    expect((await words()).every((w) => w.status == WordStatus.done.name), isTrue);
  });

  test('concurrency is read from settings', () async {
    await repo.saveSettings(const AppSettings(concurrency: 2));
    final g1 = Completer<void>();
    final g2 = Completer<void>();
    client.gates
      ..add(g1)
      ..add(g2);
    await seed(['a', 'b', 'c', 'd']);
    final c = await controller();

    final batch = c.start();
    await waitFor(() async =>
        (await words()).where((w) => w.status == WordStatus.generating.name).length == 2);

    final ws = await words();
    expect(ws[0].status, WordStatus.generating.name);
    expect(ws[1].status, WordStatus.generating.name);
    expect(ws[2].status, WordStatus.queued.name);
    expect(ws[3].status, WordStatus.queued.name);

    g1.complete();
    g2.complete();
    await batch;
    expect(c.successCount, 4);
  });

  test('progress stats are correct with mixed outcome under concurrency', () async {
    await repo.saveSettings(const AppSettings(concurrency: 3));
    await seed(['a', 'b', 'c']);
    final c = await controller();

    client.errorToThrow = const GenerationApiException(
      GenerationErrorKind.permanent,
      'API 错误 401',
    );
    await c.start();
    expect(c.failureCount, 3);
    expect(c.successCount, 0);

    client.errorToThrow = null;
    await c.retry(c.tasks.first.wordId);
    expect(c.successCount, 1);
    expect(c.failureCount, 2);
    expect(c.pendingCount, 0);
  });

  test('pause stops dispatching, queued words stay queued; resume continues', () async {
    await repo.saveSettings(const AppSettings(concurrency: 2));
    final g1 = Completer<void>();
    final g2 = Completer<void>();
    client.gates.add(g1);
    client.gates.add(g2);
    await seed(['a', 'b', 'c', 'd']);
    final c = await controller();

    final batch = c.start();
    await waitFor(() async =>
        (await words()).where((w) => w.status == WordStatus.generating.name).length == 2);

    await c.pause();
    expect(c.paused, isTrue);
    expect(c.running, isTrue); // 在飞词结算中

    // 放行在飞词:它们落定,排队词不被消费
    g1.complete();
    g2.complete();
    await batch;
    expect(c.paused, isTrue);
    expect(c.running, isFalse);
    final ws = await words();
    expect(ws[0].status, WordStatus.done.name);
    expect(ws[1].status, WordStatus.done.name);
    expect(ws[2].status, WordStatus.queued.name);
    expect(ws[3].status, WordStatus.queued.name);
    expect(c.pendingCount, 2);

    // 继续:恢复消费
    await c.resume();
    expect(c.paused, isFalse);
    expect(c.successCount, 4);
    expect((await words()).every((w) => w.status == WordStatus.done.name), isTrue);
  });

  test('cancel while paused resets queued words, in-flight settle', () async {
    await repo.saveSettings(const AppSettings(concurrency: 2));
    final g1 = Completer<void>();
    final g2 = Completer<void>();
    client.gates.add(g1);
    client.gates.add(g2);
    await seed(['a', 'b', 'c', 'd']);
    final c = await controller();

    final batch = c.start();
    await waitFor(() async =>
        (await words()).where((w) => w.status == WordStatus.generating.name).length == 2);
    await c.pause();

    await c.cancel();
    g1.complete();
    g2.complete();
    await batch;

    expect(c.cancelled, isTrue);
    final ws = await words();
    expect(ws[0].status, WordStatus.done.name);
    expect(ws[1].status, WordStatus.done.name);
    expect(ws[2].status, WordStatus.notGenerated.name);
    expect(ws[3].status, WordStatus.notGenerated.name);
    expect(c.successCount, 2);
    expect(c.pendingCount, 0);
  });

  test('cancel after pause settles resets queued words, resume cannot revive', () async {
    await repo.saveSettings(const AppSettings(concurrency: 2));
    final g1 = Completer<void>();
    final g2 = Completer<void>();
    client.gates
      ..add(g1)
      ..add(g2);
    await seed(['a', 'b', 'c', 'd']);
    final c = await controller();

    final batch = c.start();
    await waitFor(() async =>
        (await words()).where((w) => w.status == WordStatus.generating.name).length == 2);
    await c.pause();
    g1.complete();
    g2.complete();
    await batch;
    expect(c.paused, isTrue); // 已结算的暂停态

    await c.cancel();
    expect(c.cancelled, isTrue);
    expect(c.paused, isFalse);
    final ws = await words();
    expect(ws[0].status, WordStatus.done.name);
    expect(ws[1].status, WordStatus.done.name);
    expect(ws[2].status, WordStatus.notGenerated.name);
    expect(ws[3].status, WordStatus.notGenerated.name);

    // resume 对已取消批次无效(不复活)
    await c.resume();
    expect(c.cancelled, isTrue);
    expect(client.callCount, 2);
  });

  test('retry during pause enqueues but does not dispatch', () async {
    await repo.saveSettings(const AppSettings(concurrency: 2));
    final g1 = Completer<void>();
    client.gates.add(g1);
    client.errorToThrow = const GenerationApiException(
      GenerationErrorKind.permanent,
      '临时失败',
    );
    await seed(['a', 'b']);
    final c = await controller();

    final batch = c.start();
    // b 已失败;a 在飞(gate)
    await waitFor(() async =>
        (await words()).any((w) => w.status == WordStatus.failed.name));

    await c.pause();
    client.errorToThrow = null;
    final calls = client.callCount;
    final failedTask = c.tasks.firstWhere((t) => t.status == WordStatus.failed);
    await c.retry(failedTask.wordId);
    expect(client.callCount, calls); // 暂停中不派发

    g1.complete();
    await batch;
    expect(c.paused, isTrue);

    await c.resume();
    expect(c.successCount, 2); // a + b 重试
    expect(c.failureCount, 0);
  });
}
