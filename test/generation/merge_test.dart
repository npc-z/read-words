import 'package:flutter_test/flutter_test.dart';
import 'package:read_words/generation/content.dart';
import 'package:read_words/generation/merge.dart';

GeneratedWordContent content({
  required String word,
  List<Sense> senses = const [],
  List<Phrase> phrases = const [],
  List<Example> unclassified = const [],
}) {
  return GeneratedWordContent(
    word: word,
    senses: senses,
    phrases: phrases,
    unclassifiedExamples: unclassified,
  );
}

Sense sense(String pos, String meaning, List<Example> examples) =>
    Sense(pos: pos, meaning: meaning, examples: examples);

Example ex(int level, String en, {String zh = 'z'}) =>
    Example(level: level, en: en, zh: zh);

void main() {
  test('two under-producing responses merge into 3/3/3 with dedupe', () {
    final a = content(
      word: 'run',
      senses: [
        sense('v.', '跑', [ex(1, 'She runs.'), ex(1, 'He runs.'), ex(2, 'They run fast.')]),
        sense('v.', '跑', [ex(2, 'Run to school.'), ex(3, 'Having run, he rested.')]),
      ],
    );
    final b = content(
      word: 'run',
      senses: [
        // 与 a 相同的义项:例句归并 + 去重(She runs. 重复)
        sense('v.', '跑', [
          ex(1, 'She runs.'),
          ex(2, 'They run fast.'),
          ex(3, 'He ran away quickly.'),
          ex(3, 'The race was run yesterday.'),
        ]),
        // 独有义项追加
        sense('n.', '跑步', [ex(1, 'A run in the park.'), ex(2, 'A long run is tiring.')]),
      ],
    );

    final m = mergeAndSelect([a, b]);
    expect(m, isNotNull);
    expect(m!.word, 'run');
    expect(m.allExamples, hasLength(9));
    for (final lvl in [1, 2, 3]) {
      expect(m.allExamples.where((e) => e.level == lvl), hasLength(3));
    }
    // 去重:'She runs.' 只出现一次
    expect(m.allExamples.where((e) => e.en == 'She runs.'), hasLength(1));
  });

  test('senses matched by pos+meaning merge examples, unique senses appended', () {
    final a = content(
      word: 'run',
      senses: [
        sense('v.', '跑', [ex(1, 'a1'), ex(1, 'a2'), ex(1, 'a3')]),
      ],
    );
    final b = content(
      word: 'run',
      senses: [
        sense('v.', '跑', [ex(2, 'b1'), ex(2, 'b2'), ex(2, 'b3')]),
        sense('n.', '跑步', [ex(3, 'c1'), ex(3, 'c2'), ex(3, 'c3')]),
      ],
    );

    final m = mergeAndSelect([a, b])!;
    expect(m.senses, hasLength(2));
    final v = m.senses.firstWhere((s) => s.pos == 'v.');
    expect(v.examples.map((e) => e.en), containsAll(['a1', 'b3']));
    // 选中后每层 3 句
    for (final lvl in [1, 2, 3]) {
      expect(m.allExamples.where((e) => e.level == lvl), hasLength(3));
    }
  });

  test('over-production (18 sentences) trimmed to 3/3/3 without extra calls', () {
    final many = content(
      word: 'run',
      senses: [
        for (var i = 0; i < 6; i++)
          sense('v.', '义项$i', [
            ex(1, 'a$i'),
            ex(2, 'b$i'),
            ex(3, 'c$i'),
          ]),
      ],
    );

    final m = mergeAndSelect([many])!;
    expect(m.allExamples, hasLength(9));
    for (final lvl in [1, 2, 3]) {
      expect(m.allExamples.where((e) => e.level == lvl), hasLength(3));
    }
    // 无例句的义项被丢弃
    expect(m.senses, hasLength(3));
  });

  test('insufficient pool returns null', () {
    final a = content(
      word: 'run',
      senses: [
        sense('v.', '跑', [ex(1, 'a1'), ex(1, 'a2'), ex(2, 'b1')]),
      ],
    );
    expect(mergeAndSelect([a]), isNull);
  });

  test('phrases deduped and capped at 4', () {
    final a = content(
      word: 'run',
      senses: [
        sense('v.', '跑', [
          ex(1, 'a1'), ex(1, 'a2'), ex(1, 'a3'),
          ex(2, 'b1'), ex(2, 'b2'), ex(2, 'b3'),
          ex(3, 'c1'), ex(3, 'c2'), ex(3, 'c3'),
        ]),
      ],
      phrases: [
        Phrase(phrase: 'run out', en: 'e1', zh: 'z1'),
        Phrase(phrase: 'run out', en: 'e1x', zh: 'z1x'),
        Phrase(phrase: 'run into', en: 'e2', zh: 'z2'),
        Phrase(phrase: 'run away', en: 'e3', zh: 'z3'),
      ],
    );
    final b = content(
      word: 'run',
      senses: [
        sense('v.', '跑', [
          ex(1, 'a4'), ex(1, 'a5'), ex(1, 'a6'),
          ex(2, 'b4'), ex(2, 'b5'), ex(2, 'b6'),
          ex(3, 'c4'), ex(3, 'c5'), ex(3, 'c6'),
        ]),
      ],
      phrases: [
        Phrase(phrase: 'run up', en: 'e4', zh: 'z4'),
        Phrase(phrase: 'run down', en: 'e5', zh: 'z5'),
      ],
    );

    final m = mergeAndSelect([a, b])!;
    expect(m.phrases, hasLength(4));
    expect(m.phrases.map((p) => p.phrase), ['run out', 'run into', 'run away', 'run up']);
  });

  test('unclassified examples capped so at least 7 sentences attach to senses', () {
    final a = content(
      word: 'run',
      senses: [
        sense('v.', '跑', [
          ex(1, 'a1'), ex(1, 'a2'),
          ex(2, 'b1'), ex(2, 'b2'), ex(2, 'b3'),
          ex(3, 'c1'), ex(3, 'c2'), ex(3, 'c3'),
        ]),
      ],
      unclassified: [ex(1, 'u1'), ex(1, 'u2'), ex(2, 'u3')],
    );

    final m = mergeAndSelect([a])!;
    final attached = m.allExamples.length - m.unclassifiedExamples.length;
    expect(attached, greaterThanOrEqualTo(7));
    expect(m.unclassifiedExamples.length, lessThanOrEqualTo(2));
  });

  test('countErrors reports per-level and total shortfalls with pool counts', () {
    final a = content(
      word: 'run',
      senses: [sense('v.', '跑', [ex(1, 'a1'), ex(2, 'b1'), ex(3, 'c1')])],
    );
    final b = content(
      word: 'run',
      senses: [sense('v.', '跑', [ex(1, 'a2'), ex(2, 'b2'), ex(3, 'c2')])],
    );

    final errors = countErrors([a, b]);
    expect(errors, contains('L1 例句数应为 3,实际 2'));
    expect(errors, contains('L2 例句数应为 3,实际 2'));
    expect(errors, contains('L3 例句数应为 3,实际 2'));
    expect(errors, contains('例句总数应为 9,实际 6'));
  });

  test('empty attempts return null', () {
    expect(mergeAndSelect([]), isNull);
  });
}
