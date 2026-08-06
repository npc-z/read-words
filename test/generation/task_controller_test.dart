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

  test('start generates all notGenerated words sequentially to done', () async {
    await seed(['run', 'walk', 'jump']);
    final c = await controller();
    await c.start();

    expect(client.callCount, 3);
    expect(c.tasks, hasLength(3));
    expect(c.tasks.every((t) => t.status == WordStatus.done), isTrue);
    expect(c.successCount, 3);
    expect(c.failureCount, 0);
    expect(c.pendingCount, 0);
    expect(c.running, isFalse);
    expect(c.cancelled, isFalse);
    final ws = await words();
    expect(ws.every((w) => w.status == WordStatus.done.name), isTrue);
  });

  test('status transitions queued -> generating -> done are visible', () async {
    await repo.saveSettings(const AppSettings(concurrency: 1));
    final gate = Completer<void>();
    client = FakeClient(gate: gate);
    service = GenerationService(client: client, repositories: repo);
    await seed(['run', 'walk']);
    final c = await controller();

    final batch = c.start();
    await waitFor(() async =>
        (await words()).first.status == WordStatus.generating.name);

    expect((await words())[0].status, WordStatus.generating.name);
    expect((await words())[1].status, WordStatus.queued.name);

    gate.complete();
    await batch;

    final ws = await words();
    expect(ws.every((w) => w.status == WordStatus.done.name), isTrue);
  });

  test('failures are recorded with reason, batch continues', () async {
    client.errorToThrow = const GenerationApiException(
      GenerationErrorKind.permanent,
      'API 错误 401',
    );
    service = GenerationService(client: client, repositories: repo);
    await seed(['run', 'walk']);
    final c = await controller();
    await c.start();

    expect(c.failureCount, 2);
    expect(c.successCount, 0);
    expect(c.tasks.every((t) => t.status == WordStatus.failed), isTrue);
    expect(c.tasks.every((t) => t.error != null), isTrue);
    final ws = await words();
    expect(ws.every((w) => w.status == WordStatus.failed.name), isTrue);
  });

  test('retry re-enqueues a failed word and regenerates it', () async {
    client.errorToThrow = const GenerationApiException(
      GenerationErrorKind.permanent,
      '临时失败',
    );
    service = GenerationService(client: client, repositories: repo);
    await seed(['run']);
    final c = await controller();
    await c.start();

    final task = c.tasks.single;
    expect(task.status, WordStatus.failed);
    expect(task.error, isNotNull);
    final firstCalls = client.callCount;

    client.errorToThrow = null;
    await c.retry(task.wordId);

    expect(task.status, WordStatus.done);
    expect(task.error, isNull);
    expect(client.callCount, firstCalls + 1);
    final w = (await words()).single;
    expect(w.status, WordStatus.done.name);
  });

  test('retry on a non-failed word is ignored', () async {
    await seed(['run']);
    final c = await controller();
    await c.start();

    final task = c.tasks.single;
    final calls = client.callCount;
    await c.retry(task.wordId);
    expect(client.callCount, calls);
    expect(task.status, WordStatus.done);
  });

  test('cancel resets a word that fails after cancel to notGenerated', () async {
    final gate = Completer<void>();
    client = FakeClient(gate: gate);
    client.errorToThrow = const GenerationApiException(
      GenerationErrorKind.permanent,
      '取消后才失败',
    );
    service = GenerationService(client: client, repositories: repo);
    await seed(['run']);
    final c = await controller();

    final batch = c.start();
    await waitFor(() async =>
        (await words()).single.status == WordStatus.generating.name);

    c.cancel();
    gate.complete();
    await batch;

    final task = c.tasks.single;
    expect(task.status, WordStatus.notGenerated);
    expect(task.error, isNull);
    expect((await words()).single.status, WordStatus.notGenerated.name);
    expect(c.running, isFalse);
  });

  test('cancel keeps finished words, resets remaining to notGenerated', () async {
    await repo.saveSettings(const AppSettings(concurrency: 1));
    final gate = Completer<void>();
    client = FakeClient(gate: gate);
    service = GenerationService(client: client, repositories: repo);
    await seed(['run', 'walk', 'jump']);
    final c = await controller();

    final batch = c.start();
    await waitFor(() async =>
        (await words()).first.status == WordStatus.generating.name);
    expect(c.running, isTrue);

    c.cancel();
    gate.complete();
    await batch;

    final ws = await words();
    expect(ws[0].status, WordStatus.done.name);
    expect(ws[1].status, WordStatus.notGenerated.name);
    expect(ws[2].status, WordStatus.notGenerated.name);
    expect(c.tasks[0].status, WordStatus.done);
    expect(c.tasks[1].status, WordStatus.notGenerated);
    expect(c.tasks[2].status, WordStatus.notGenerated);
    expect(c.successCount, 1);
    expect(c.pendingCount, 0);
    expect(c.running, isFalse);
    expect(c.cancelled, isTrue);
  });

  test('start with nothing to generate is a no-op', () async {
    await seed(['run']);
    final w = (await words()).single;
    await repo.setWordStatus(w.id, WordStatus.done);
    final c = await controller();
    await c.start();
    expect(client.callCount, 0);
    expect(c.tasks, isEmpty);
    expect(c.successCount, 0);
    expect(c.failureCount, 0);
    expect(c.pendingCount, 0);
  });
}
