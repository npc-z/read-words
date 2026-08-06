import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:read_words/data/app_database.dart';
import 'package:read_words/data/repositories.dart';
import 'package:read_words/data/settings.dart';
import 'package:read_words/generation/generation_queue.dart';
import 'package:read_words/generation/generation_service.dart';
import 'package:read_words/ui/review_queue_page.dart';
import 'package:read_words/ui/word_detail_page.dart';
import 'package:read_words/ui/word_list_page.dart';

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

  Future<WordSet> addSet(String name) async {
    final id = await repo.createWordSet(name);
    return (await repo.wordSets()).firstWhere((s) => s.id == id);
  }

  Future<int> addWord(int setId, String head) async {
    await repo.addWords(setId, [head]);
    return (await repo.wordsInSet(setId)).last.id;
  }

  Future<void> writeDueState(int wordId, {int daysAgo = 0}) async {
    await db
        .into(db.reviewStatesTable)
        .insertOnConflictUpdate(
          ReviewStatesTableCompanion.insert(
            wordId: Value(wordId),
            known: const Value(true),
            interval: const Value(1),
            nextReviewAt: Value(
              DateTime.now().subtract(Duration(days: daysAgo)),
            ),
            updatedAt: Value(DateTime.now()),
            deviceSeq: const Value(1),
          ),
        );
  }

  Future<void> pumpReviewPage(WidgetTester tester, WordSet wordSet) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ReviewQueuePage(
          wordSet: wordSet,
          repositories: repo,
          queue: queue,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('word list has review entry with due badge that opens the page', (
    tester,
  ) async {
    final set = await addSet('高考词汇');
    await addWord(set.id, 'run');
    final due = await addWord(set.id, 'apple');
    await writeDueState(due);

    await tester.pumpWidget(
      MaterialApp(
        home: WordListPage(wordSet: set, repositories: repo, queue: queue),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('复习'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.byTooltip('复习'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, '复习'), findsOneWidget);
    expect(find.text('apple'), findsOneWidget);
  });

  testWidgets('review page lists due words, excludes future and unmarked', (
    tester,
  ) async {
    final set = await addSet('s');
    final due = await addWord(set.id, 'due');
    final future = await addWord(set.id, 'future');
    await addWord(set.id, 'unmarked');
    await writeDueState(due);
    await writeDueState(future, daysAgo: -3);

    await pumpReviewPage(tester, set);

    expect(find.text('due'), findsOneWidget);
    expect(find.text('future'), findsNothing);
    expect(find.text('unmarked'), findsNothing);
    expect(find.text('今天到期'), findsOneWidget);
  });

  testWidgets('review page shows empty state when nothing due', (tester) async {
    final set = await addSet('s');
    await addWord(set.id, 'run');
    await addWord(set.id, 'apple');

    await pumpReviewPage(tester, set);

    expect(find.text('今天没有到期词'), findsOneWidget);
  });

  testWidgets('completing a review advances interval and removes from list', (
    tester,
  ) async {
    final set = await addSet('s');
    final due = await addWord(set.id, 'due');
    await writeDueState(due);

    await pumpReviewPage(tester, set);
    expect(find.text('due'), findsOneWidget);

    await tester.tap(find.byTooltip('完成复习'));
    await tester.pumpAndSettle();

    final state = await repo.reviewStateFor(due);
    expect(state!.interval, 3);
    expect(state.nextReviewAt, isNotNull);
    expect(find.text('due'), findsNothing);
    expect(find.text('今天没有到期词'), findsOneWidget);
    expect(find.textContaining('天后再来'), findsOneWidget);
  });

  testWidgets('tapping a due word opens detail in review mode', (tester) async {
    final set = await addSet('s');
    final due = await addWord(set.id, 'due');
    await writeDueState(due);
    await repo.saveMaterial(
      due,
      MaterialData(
        sensesJson: jsonEncode([
          {
            'pos': 'v.',
            'meaning': 'm',
            'examples': [
              {'level': 1, 'en': 'a1', 'zh': 'z1'},
              {'level': 2, 'en': 'b1', 'zh': 'z2'},
              {'level': 3, 'en': 'c1', 'zh': 'z3'},
            ],
          },
        ]),
      ),
    );

    await pumpReviewPage(tester, set);
    await tester.tap(find.text('due'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'due'), findsOneWidget);
    // 复习模式(逐句精读器)特征:左右切换箭头,而非学习模式的层次区块
    expect(find.byIcon(Icons.chevron_left), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    expect(find.text('简单句 · 核心用法'), findsNothing);
  });

  testWidgets('detail page without initialMode still uses settings default', (
    tester,
  ) async {
    final set = await addSet('s');
    final wordId = await addWord(set.id, 'mode');
    await repo.saveSettings(
      const AppSettings(defaultViewMode: ViewMode.lookup),
    );
    await repo.saveMaterial(
      wordId,
      MaterialData(
        sensesJson: jsonEncode([
          {
            'pos': 'v.',
            'meaning': 'm',
            'examples': [
              {'level': 1, 'en': 'a1', 'zh': 'z1'},
            ],
          },
        ]),
      ),
    );
    final word = (await repo.wordsInSet(set.id)).first;

    await tester.pumpWidget(
      MaterialApp(
        home: WordDetailPage(word: word, repositories: repo, queue: queue),
      ),
    );
    await tester.pumpAndSettle();

    // 查阅模式特征:词性行 + 释义,无复习箭头
    expect(find.byIcon(Icons.chevron_left), findsNothing);
    expect(find.text('v.'), findsOneWidget);
  });

  testWidgets('marking known/unknown on detail page enters review cycle', (
    tester,
  ) async {
    final set = await addSet('s');
    final wordId = await addWord(set.id, 'mark');
    await repo.saveMaterial(
      wordId,
      MaterialData(
        sensesJson: jsonEncode([
          {
            'pos': 'v.',
            'meaning': 'm',
            'examples': [
              {'level': 1, 'en': 'a1', 'zh': 'z1'},
            ],
          },
        ]),
      ),
    );
    final word = (await repo.wordsInSet(set.id)).first;

    await tester.pumpWidget(
      MaterialApp(
        home: WordDetailPage(word: word, repositories: repo, queue: queue),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('认识'), findsOneWidget);
    expect(find.text('不认识'), findsOneWidget);

    await tester.tap(find.text('认识'));
    await tester.pumpAndSettle();

    final state = await repo.reviewStateFor(wordId);
    expect(state, isNotNull);
    expect(state!.known, true);
    expect(state.interval, 1);
    expect(state.nextReviewAt, isNotNull);
    expect(find.text('已标记认识'), findsOneWidget);

    // 标记后次日进入到期列表
    await writeDueState(wordId);
    await tester.pumpWidget(
      MaterialApp(
        home: ReviewQueuePage(wordSet: set, repositories: repo, queue: queue),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('mark'), findsOneWidget);
  });
}
