import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:read_words/data/app_database.dart';
import 'package:read_words/data/repositories.dart';
import 'package:read_words/generation/deepseek_client.dart';
import 'package:read_words/generation/generation_service.dart';
import 'package:read_words/ui/task_console_page.dart';
import 'package:read_words/ui/word_list_page.dart';

import '../generation/fake_client.dart';

void main() {
  late AppDatabase db;
  late Repositories repo;
  late FakeClient client;
  late GenerationService service;
  late WordSet wordSet;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = Repositories(db);
    client = FakeClient();
    service = GenerationService(client: client, repositories: repo);
  });

  tearDown(() => db.close());

  Future<void> seed(List<String> words) async {
    final setId = await repo.createWordSet('test');
    await repo.addWords(setId, words);
    wordSet = (await repo.wordSets()).first;
  }

  testWidgets('console shows progress card, stats, failure reasons and retry works', (tester) async {
    client.errorToThrow = const GenerationApiException(
      GenerationErrorKind.permanent,
      'API 错误 401',
    );
    await seed(['run', 'walk']);

    await tester.pumpWidget(MaterialApp(
      home: TaskConsolePage(wordSet: wordSet, repositories: repo, service: service),
    ));
    await tester.pumpAndSettle();

    // 进度卡:统计 + 徽章
    expect(find.textContaining('成功 0'), findsOneWidget);
    expect(find.textContaining('失败 2'), findsOneWidget);
    expect(find.text('已完成'), findsOneWidget);
    // 词表:两个词 + 失败原因
    expect(find.text('run'), findsOneWidget);
    expect(find.text('walk'), findsOneWidget);
    expect(find.textContaining('API 错误 401'), findsNWidgets(2));
    expect(find.byTooltip('重试'), findsNWidgets(2));

    // 单点重试:第一个词重新生成成功
    client.errorToThrow = null;
    await tester.tap(find.byTooltip('重试').first);
    await tester.pumpAndSettle();

    expect(find.textContaining('成功 1'), findsOneWidget);
    expect(find.textContaining('失败 1'), findsOneWidget);
    expect(find.byTooltip('重试'), findsOneWidget);
  });

  testWidgets('cancel keeps finished words and resets remaining to notGenerated', (tester) async {
    final gate = Completer<void>();
    client = FakeClient(gate: gate);
    service = GenerationService(client: client, repositories: repo);
    await seed(['run', 'walk']);

    await tester.pumpWidget(MaterialApp(
      home: TaskConsolePage(wordSet: wordSet, repositories: repo, service: service),
    ));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(find.text('生成中'), findsWidgets);

    await tester.tap(find.text('取消'));
    await tester.pump();
    gate.complete();
    await tester.pumpAndSettle();

    expect(find.text('已取消'), findsOneWidget);
    expect(find.textContaining('成功 1'), findsOneWidget);
    final ws = await repo.wordsInSet(wordSet.id);
    expect(ws[0].status, WordStatus.done.name);
    expect(ws[1].status, WordStatus.notGenerated.name);
  });

  testWidgets('word list page has entry that opens the console', (tester) async {
    await seed([]);

    await tester.pumpWidget(MaterialApp(
      home: WordListPage(wordSet: wordSet, repositories: repo),
    ));
    await tester.pumpAndSettle();

    expect(find.byTooltip('开始生成'), findsOneWidget);
    await tester.tap(find.byTooltip('开始生成'));
    await tester.pumpAndSettle();

    expect(find.text('生成任务'), findsOneWidget);
    expect(find.textContaining('成功 0'), findsOneWidget);
  });
}
