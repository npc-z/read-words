import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:read_words/data/app_database.dart';
import 'package:read_words/data/repositories.dart';
import 'package:read_words/generation/content.dart';
import 'package:read_words/ui/word_detail_page.dart';

WordMaterial sampleMaterial() {
  final senses = [
    Sense(pos: 'v.', meaning: 'to move using your legs', examples: [
      Example(level: 1, en: 'I run every morning.', zh: '我每天早上跑步。'),
      Example(level: 1, en: 'The children ran across the park.', zh: '孩子们跑过公园。'),
      Example(level: 1, en: 'She runs fast.', zh: '她跑得很快。'),
      Example(level: 2, en: 'He runs faster than anyone in class.', zh: '他跑得比班上任何人都快。'),
      Example(level: 2, en: 'The dog that barked was running in circles.', zh: '那只叫的狗在绕圈跑。'),
      Example(level: 2, en: 'Although it rained, we kept running along the river.', zh: '虽然下雨了,我们仍沿着河边跑。'),
      Example(level: 3, en: 'Having run the length of the corridor, he collapsed against the door.', zh: '跑完走廊后,他瘫靠在门上。'),
      Example(level: 3, en: 'The committee, having deliberated, concluded the proposal.', zh: '委员会审议后通过了提案。'),
      Example(level: 3, en: 'While the storm raged, the children slept in the cabin.', zh: '暴风雨肆虐时,孩子们在小屋里睡着了。'),
    ]),
  ];
  final phrases = [
    Phrase(phrase: 'run out of', en: 'We ran out of milk.', zh: '我们的牛奶喝完了。'),
  ];
  return WordMaterial(
    wordId: 1,
    phoneticUk: '/rʌn/',
    phoneticUs: '/rʌn/',
    sensesJson: jsonEncode(senses.map((s) => s.toJson()).toList()),
    phrasesJson: jsonEncode(phrases.map((p) => p.toJson()).toList()),
    unclassifiedExamplesJson: '[]',
    rawHtml: '',
    source: 'ai',
  );
}

Future<Word> seedWord(AppDatabase db) async {
  final repo = Repositories(db);
  final setId = await repo.createWordSet('test');
  await repo.addWords(setId, ['run']);
  final word = (await repo.wordsInSet(setId)).first;
  await repo.saveMaterial(
    word.id,
    MaterialData(
      phoneticUk: '/rʌn/',
      phoneticUs: '/rʌn/',
      sensesJson: jsonEncode(
        [
          Sense(pos: 'v.', meaning: 'to move', examples: [
            Example(level: 1, en: 'I run every morning.', zh: '我每天早上跑步。'),
            Example(level: 2, en: 'He runs faster than anyone in class.', zh: '他跑得比班上任何人都快。'),
            Example(level: 3, en: 'Having run the length of the corridor, he collapsed.', zh: '跑完走廊后,他瘫倒了。'),
          ]),
        ].map((s) => s.toJson()).toList(),
      ),
      phrasesJson: '[]',
      source: 'ai',
    ),
  );
  return word;
}

void main() {
  testWidgets('word detail renders study mode with level groups', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final repo = Repositories(db);
    final word = await seedWord(db);

    await tester.pumpWidget(MaterialApp(
      home: WordDetailPage(word: word, repositories: repo),
    ));
    await tester.pumpAndSettle();

    expect(find.text('run'), findsWidgets);
    expect(find.textContaining('简单句'), findsWidgets);

    await db.close();
  });

  testWidgets('display config switches to zh-only', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final repo = Repositories(db);
    final word = await seedWord(db);

    await tester.pumpWidget(MaterialApp(
      home: WordDetailPage(word: word, repositories: repo),
    ));
    await tester.pumpAndSettle();

    // 默认中英双语:例句英文可见
    expect(find.text('I run every morning.'), findsOneWidget);

    // 打开展示配置菜单,切到"仅中文"
    await tester.tap(find.byTooltip('展示配置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('仅中文'));
    await tester.pumpAndSettle();

    // 英文例句消失,中文例句仍在
    expect(find.text('I run every morning.'), findsNothing);
    expect(find.text('我每天早上跑步。'), findsOneWidget);
    await db.close();
  });
}
