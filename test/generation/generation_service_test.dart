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

  /// 模拟模型常见错误输出:6 个义项 × 每层 1 句 = 18 句(每层 6 句)
  final badRunContent = {
    'word': 'run',
    'phonetic': {'uk': '/rʌn/', 'us': '/rʌn/'},
    'senses': [
      for (var s = 0; s < 6; s++)
        {
          'pos': 'v.',
          'meaning': 'm$s',
          'examples': [
            {'level': 1, 'en': 'a$s', 'zh': 'z$s'},
            {'level': 2, 'en': 'b$s', 'zh': 'z$s'},
            {'level': 3, 'en': 'c$s', 'zh': 'z$s'},
          ],
        },
    ],
    'phrases': [],
    'unclassified_examples': [],
  };

  /// 数量不足的响应:L1×2/L2×2/L3×3 = 7 句,两次去重合并后恰好 3/3/3
  Map<String, dynamic> run7({required String suffix}) => {
        'word': 'run',
        'phonetic': {'uk': '/rʌn/', 'us': '/rʌn/'},
        'senses': [
          {
            'pos': 'v.',
            'meaning': '跑',
            'examples': [
              {'level': 1, 'en': 'a1', 'zh': 'z'},
              {'level': 1, 'en': 'a2$suffix', 'zh': 'z'},
              {'level': 2, 'en': 'b1', 'zh': 'z'},
              {'level': 2, 'en': 'b2$suffix', 'zh': 'z'},
              {'level': 3, 'en': 'c1$suffix', 'zh': 'z'},
              {'level': 3, 'en': 'c2$suffix', 'zh': 'z'},
              {'level': 3, 'en': 'c3$suffix', 'zh': 'z'},
            ],
          },
        ],
        'phrases': [],
        'unclassified_examples': [],
      };

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

  test('content validation failure marks word as failed', () async {
    // 模拟真实场景:模型返回 L1×4/L2×3/L3×2,不满足每层 3 句(§4.2)
    client.contentOverride = {
      'word': 'good',
      'phonetic': {'uk': '/g/', 'us': '/g/'},
      'senses': [
        {
          'pos': 'adj.',
          'meaning': 'm',
          'examples': [
            {'level': 1, 'en': 'a1', 'zh': 'z1'},
            {'level': 1, 'en': 'a2', 'zh': 'z2'},
            {'level': 1, 'en': 'a3', 'zh': 'z3'},
            {'level': 1, 'en': 'a4', 'zh': 'z4'},
            {'level': 2, 'en': 'b1', 'zh': 'z5'},
            {'level': 2, 'en': 'b2', 'zh': 'z6'},
            {'level': 3, 'en': 'c1', 'zh': 'z7'},
            {'level': 3, 'en': 'c2', 'zh': 'z8'},
          ],
        },
      ],
      'phrases': [],
      'unclassified_examples': [],
    };
    final wordId = await addWord('good');
    final o = await service.generateWord(wordId);

    expect(o.failed, isTrue);
    final w = await repo.wordById(wordId);
    expect(w!.status, WordStatus.failed.name);
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
    'over-production (18 sentences) succeeds via selection without retry',
    () async {
      client.contentByCall.addAll([badRunContent]);
      final wordId = await addWord('run');
      final o = await service.generateWord(wordId);

      expect(o.failed, isFalse);
      expect(client.callCount, 1);

      final m = await repo.materialFor(wordId);
      final senses = jsonDecode(m!.sensesJson) as List;
      expect(senses, hasLength(3));
      final examples = [
        for (final s in senses) ...(s['examples'] as List),
      ];
      expect(examples, hasLength(9));
      final w = await repo.wordById(wordId);
      expect(w!.status, WordStatus.done.name);
    },
  );

  test('two under-producing responses are merged and succeed', () async {
    // 两次各 7 句(重叠 a1/b1),去重合并后 3/3/3
    client.contentByCall.addAll([run7(suffix: ''), run7(suffix: 'x')]);
    final wordId = await addWord('run');
    final o = await service.generateWord(wordId);

    expect(o.failed, isFalse);
    expect(client.callCount, 2);
    expect(client.lastFeedback, contains('L1 例句数应为 3'));

    final m = await repo.materialFor(wordId);
    final senses = jsonDecode(m!.sensesJson) as List;
    final examples = [
      for (final s in senses) ...(s['examples'] as List),
    ];
    expect(examples, hasLength(9));
    final w = await repo.wordById(wordId);
    expect(w!.status, WordStatus.done.name);
  });

  test('three under-producing responses merged but still insufficient', () async {
    client.contentByCall.addAll([run7(suffix: ''), run7(suffix: ''), run7(suffix: '')]);
    final wordId = await addWord('run');
    final o = await service.generateWord(wordId);

    expect(o.failed, isTrue);
    expect(client.callCount, 3);
    expect(o.error, contains('L1 例句数应为 3'));
    final w = await repo.wordById(wordId);
    expect(w!.status, WordStatus.failed.name);
  });

  test('word-mismatch response excluded from pool, retried then succeeds', () async {
    client.contentByCall.addAll([
      {
        'word': 'wrong',
        'phonetic': {'uk': '/x/', 'us': '/x/'},
        'senses': [
          {
            'pos': 'v.',
            'meaning': 'm',
            'examples': [
              {'level': 1, 'en': 'x1', 'zh': 'z'},
              {'level': 2, 'en': 'x2', 'zh': 'z'},
              {'level': 3, 'en': 'x3', 'zh': 'z'},
            ],
          },
        ],
        'phrases': [],
        'unclassified_examples': [],
      },
      null, // 第二次默认合法 9 句
    ]);
    final wordId = await addWord('run');
    final o = await service.generateWord(wordId);

    expect(o.failed, isFalse);
    expect(client.callCount, 2);
    expect(client.lastFeedback, contains('词头不一致'));
    final m = await repo.materialFor(wordId);
    expect(m, isNotNull);
    // 错误词头的例句未被并入
    expect(jsonEncode(m!.sensesJson), isNot(contains('x1')));
    final w = await repo.wordById(wordId);
    expect(w!.status, WordStatus.done.name);
  });

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
