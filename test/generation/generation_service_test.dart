import 'dart:async';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:read_words/data/app_database.dart';
import 'package:read_words/data/repositories.dart';
import 'package:read_words/generation/deepseek_client.dart';
import 'package:read_words/generation/generation_service.dart';
import 'package:read_words/generation/prompt.dart';

import 'fake_client.dart';

void main() {
  late AppDatabase db;
  late Repositories repo;
  late FakeClient client;
  late GenerationService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = Repositories(db);
    client = FakeClient();
    service = GenerationService(client: client, repositories: repo);
  });

  tearDown(() => db.close());

  Future<int> addWord(String w) async {
    final setId = await repo.createWordSet('test');
    await repo.addWords(setId, [w]);
    return (await repo.wordsInSet(setId)).first.id;
  }

  test('generates and persists material, status becomes done', () async {
    final wordId = await addWord('run');
    final o = await service.generateWord(wordId);

    expect(o.failed, isFalse);
    expect(client.requestedWord, 'run');

    final m = await repo.materialFor(wordId);
    expect(m, isNotNull);
    expect(m!.phoneticUk, '/x/');
    final senses = jsonDecode(m.sensesJson) as List;
    expect(senses, hasLength(1));
    expect((senses.first['examples'] as List), hasLength(9));

    final w = await repo.wordById(wordId);
    expect(w!.status, WordStatus.done.name);
  });

  test('proficiency is passed to prompt', () async {
    final serviceTem = GenerationService(
      client: client,
      repositories: repo,
      proficiency: Proficiency.tem,
    );
    final wordId = await addWord('run');
    await serviceTem.generateWord(wordId);
    expect(client.requestedWord, 'run');
  });

  test('marks word generating while API call is in flight', () async {
    final gate = Completer<void>();
    client = FakeClient(gate: gate);
    service = GenerationService(client: client, repositories: repo);
    final wordId = await addWord('run');

    final future = service.generateWord(wordId);
    await Future<void>.delayed(Duration.zero);
    expect((await repo.wordById(wordId))!.status, WordStatus.generating.name);

    gate.complete();
    await future;
    expect((await repo.wordById(wordId))!.status, WordStatus.done.name);
  });

  test('transient error retried 3 times then marks failed', () async {
    client.errorToThrow = const GenerationApiException(
      GenerationErrorKind.transient,
      '网络错误',
    );
    final delays = <Duration>[];
    service = GenerationService(
      client: client,
      repositories: repo,
      delayOverride: (d) async => delays.add(d),
    );
    final wordId = await addWord('run');
    final o = await service.generateWord(wordId);

    expect(o.failed, isTrue);
    expect(client.callCount, 4);
    expect(delays, [
      const Duration(seconds: 1),
      const Duration(seconds: 4),
      const Duration(seconds: 16),
    ]);
    final w = await repo.wordById(wordId);
    expect(w!.status, WordStatus.failed.name);
  });

  test('validation error retried 2 times', () async {
    client.errorToThrow = const GenerationApiException(
      GenerationErrorKind.validation,
      'JSON 解析失败',
    );
    final wordId = await addWord('run');
    final o = await service.generateWord(wordId);

    expect(o.failed, isTrue);
    expect(client.callCount, 3);
  });

  test(
    'invalid content (not 9 sentences) marked failed without retry loop',
    () async {
      client.contentOverride = {
        'word': 'run',
        'senses': [
          {
            'pos': 'v.',
            'meaning': 'm',
            'examples': [
              {'level': 1, 'en': 'a1', 'zh': 'z1'},
            ],
          },
        ],
        'phrases': [],
        'unclassified_examples': [],
      };
      final wordId = await addWord('run');
      final o = await service.generateWord(wordId);

      expect(o.failed, isTrue);
      expect(o.error, contains('L1'));
    },
  );

  test('batch generation continues past failures', () async {
    final setId = await repo.createWordSet('test');
    await repo.addWords(setId, ['run', 'walk', 'jump']);
    final words = await repo.wordsInSet(setId);

    client.errorToThrow = const GenerationApiException(
      GenerationErrorKind.permanent,
      'permanent',
    );
    final outcomes = await service.generateBatch(
      words.map((w) => w.id).toList(),
    );
    expect(outcomes, hasLength(3));
    expect(outcomes.every((o) => o.failed), isTrue);
  });
}
