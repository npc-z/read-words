import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:read_words/data/app_database.dart';
import 'package:read_words/data/repositories.dart';
import 'package:read_words/data/settings.dart';
import 'package:read_words/generation/budget.dart';
import 'package:read_words/generation/deepseek_client.dart';
import 'package:read_words/generation/generation_queue.dart';
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

  Future<GenerationQueue> queue({BudgetLedger? budget}) async {
    return GenerationQueue(
      repositories: repo,
      service: service,
      budget: budget ?? BudgetLedger(repositories: repo),
    );
  }

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
      home: TaskConsolePage(
        wordSet: wordSet,
        repositories: repo,
        queue: await queue(),
      ),
    ));
    await tester.pumpAndSettle();

    // 进度卡:统计 + 徽章
    expect(find.textContaining('成功 0'), findsOneWidget);
    expect(find.textContaining('失败 2'), findsOneWidget);
    expect(find.widgetWithText(Chip, '已完成'), findsOneWidget);
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

  testWidgets('cancel resets queued words, in-flight words settle', (tester) async {
    await repo.saveSettings(const AppSettings(concurrency: 1));
    final gate = Completer<void>();
    client = FakeClient(gate: gate);
    service = GenerationService(client: client, repositories: repo);
    await seed(['run', 'walk']);

    await tester.pumpWidget(MaterialApp(
      home: TaskConsolePage(
        wordSet: wordSet,
        repositories: repo,
        queue: await queue(),
      ),
    ));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(find.text('生成中'), findsWidgets);

    await tester.tap(find.text('取消'));
    await tester.pump();
    gate.complete();
    await tester.pumpAndSettle();

    expect(find.widgetWithText(Chip, '已取消'), findsOneWidget);
    expect(find.textContaining('成功 1'), findsOneWidget);
    final ws = await repo.wordsInSet(wordSet.id);
    expect(ws[0].status, WordStatus.done.name);
    expect(ws[1].status, WordStatus.notGenerated.name);
  });

  testWidgets('word list page has entry that opens the console', (tester) async {
    await seed([]);

    await tester.pumpWidget(MaterialApp(
      home: WordListPage(
        wordSet: wordSet,
        repositories: repo,
        queue: await queue(),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byTooltip('开始生成'), findsOneWidget);
    await tester.tap(find.byTooltip('开始生成'));
    await tester.pumpAndSettle();

    expect(find.text('生成任务'), findsOneWidget);
    expect(find.textContaining('成功 0'), findsOneWidget);
  });

  testWidgets('budget exhaustion shows 已达今日预算 and continue resumes next day', (tester) async {
    await repo.saveSettings(const AppSettings(dailyReadingX: 1, budgetMultiple: 1));
    await seed(['run', 'walk']);
    var now = DateTime(2026, 8, 6, 10, 30);

    await tester.pumpWidget(MaterialApp(
      home: TaskConsolePage(
        wordSet: wordSet,
        repositories: repo,
        queue: await queue(
          budget: BudgetLedger(repositories: repo, now: () => now),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // 达限:徽章 + 预算条 + 继续按钮;run 完成,walk 保留排队
    expect(find.widgetWithText(Chip, '已达今日预算'), findsOneWidget);
    expect(find.text('继续下一批次'), findsOneWidget);
    expect(find.text('今日预算 1/1'), findsOneWidget);
    expect(find.textContaining('成功 1'), findsOneWidget);
    expect(find.text('walk'), findsOneWidget);
    expect(find.text('排队中'), findsOneWidget);

    // 次日自然日重置后继续
    now = DateTime(2026, 8, 7, 8, 0);
    await tester.tap(find.text('继续下一批次'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(Chip, '已完成'), findsOneWidget);
    expect(find.textContaining('成功 2'), findsOneWidget);
    expect(find.widgetWithText(Chip, '已达今日预算'), findsNothing);
  });

  testWidgets('continue on the same day shows a snackbar instead of silent no-op', (tester) async {
    await repo.saveSettings(const AppSettings(dailyReadingX: 1, budgetMultiple: 1));
    await seed(['run', 'walk']);
    var now = DateTime(2026, 8, 6, 10, 30);

    await tester.pumpWidget(MaterialApp(
      home: TaskConsolePage(
        wordSet: wordSet,
        repositories: repo,
        queue: await queue(
          budget: BudgetLedger(repositories: repo, now: () => now),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('继续下一批次'));
    await tester.pumpAndSettle();

    expect(find.text('已达今日预算,次日重置后可继续'), findsOneWidget);
    expect(find.widgetWithText(Chip, '已达今日预算'), findsOneWidget); // 仍达限
  });

  testWidgets('pause stops dispatch, resume continues, badge reflects state', (tester) async {
    await repo.saveSettings(const AppSettings(concurrency: 2));
    final g1 = Completer<void>();
    final g2 = Completer<void>();
    client.gates
      ..add(g1)
      ..add(g2);
    await seed(['run', 'walk', 'jump']);

    await tester.pumpWidget(MaterialApp(
      home: TaskConsolePage(
        wordSet: wordSet,
        repositories: repo,
        queue: await queue(),
      ),
    ));
    // 在飞词有 spinner 动画,用定长 pump 而非 pumpAndSettle
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }

    await tester.tap(find.text('暂停'));
    await tester.pump();
    await tester.pump();
    expect(find.widgetWithText(Chip, '已暂停'), findsOneWidget);
    expect(find.text('继续'), findsOneWidget);
    expect(find.text('取消'), findsOneWidget);

    // 放行在飞词:结算完成,排队词保持 queued
    g1.complete();
    g2.complete();
    await tester.pumpAndSettle();
    expect(find.text('排队中'), findsOneWidget); // jump 仍在排队

    // 继续:全部完成
    await tester.tap(find.text('继续'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(Chip, '已完成'), findsOneWidget);
    expect(find.textContaining('成功 3'), findsOneWidget);
    expect((await repo.wordsInSet(wordSet.id))
        .every((w) => w.status == WordStatus.done.name), isTrue);
  });
}
