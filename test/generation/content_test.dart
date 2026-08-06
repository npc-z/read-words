import 'package:flutter_test/flutter_test.dart';
import 'package:read_words/generation/content.dart';

Example ex(int level, String en, [String zh = '中文']) =>
    Example(level: level, en: en, zh: zh);

void main() {
  group('fromJson', () {
    test('parses full schema', () {
      final json = {
        'word': 'run',
        'phonetic': {'uk': '/rʌn/', 'us': '/rʌn/'},
        'senses': [
          {
            'pos': 'v.',
            'meaning': 'to move',
            'examples': [
              {'level': 1, 'en': 'I run.', 'zh': '我跑。'},
            ],
          },
        ],
        'phrases': [
          {'phrase': 'run out of', 'en': 'We ran out.', 'zh': '我们用完了。'},
        ],
        'unclassified_examples': [],
      };
      final c = GeneratedWordContent.fromJson(json);
      expect(c, isNotNull);
      expect(c!.word, 'run');
      expect(c.phoneticUk, '/rʌn/');
      expect(c.senses, hasLength(1));
      expect(c.senses.first.pos, 'v.');
      expect(c.senses.first.examples.single.en, 'I run.');
      expect(c.phrases.single.phrase, 'run out of');
    });

    test('rejects invalid levels', () {
      final json = {
        'word': 'x',
        'senses': [
          {
            'pos': 'n.',
            'meaning': 'm',
            'examples': [
              {'level': 9, 'en': 'a', 'zh': 'b'},
            ],
          },
        ],
      };
      final c = GeneratedWordContent.fromJson(json);
      expect(c, isNotNull);
      expect(c!.senses.first.examples, isEmpty);
    });
  });

  group('validateContent', () {
    GeneratedWordContent make({
      int l1 = 3,
      int l2 = 3,
      int l3 = 3,
      int unclassified = 0,
      int phrases = 2,
    }) {
      // unclassified 例句也参与 level 全局配额:从 L2/L3 各借 1 句
      final unExs = <Example>[];
      for (var i = 0; i < unclassified; i++) {
        unExs.add(ex(i % 2 == 0 ? 2 : 3, 'u$i'));
      }
      final effL2 = l2 - (unclassified >= 1 ? 1 : 0);
      final effL3 = l3 - (unclassified >= 2 ? 1 : 0);
      final senses = <Sense>[
        Sense(
          pos: 'v.',
          meaning: 'm',
          examples: [
            for (var i = 0; i < l1; i++) ex(1, 'a$i'),
            for (var i = 0; i < effL2; i++) ex(2, 'b$i'),
          ],
        ),
        Sense(
          pos: 'n.',
          meaning: 'n',
          examples: [for (var i = 0; i < effL3; i++) ex(3, 'c$i')],
        ),
      ];
      return GeneratedWordContent(
        word: 'run',
        senses: senses,
        unclassifiedExamples: unExs,
        phrases: [
          for (var i = 0; i < phrases; i++)
            Phrase(phrase: 'p$i', en: 'e$i', zh: 'z$i'),
        ],
      );
    }

    test('valid 9 sentences', () {
      final r = validateContent(make());
      expect(r.ok, isTrue, reason: r.errors.join('; '));
    });

    test('level counts must be exactly 3', () {
      final r = validateContent(make(l1: 2));
      expect(r.ok, isFalse);
      expect(r.errors.any((e) => e.contains('L1')), isTrue);
    });

    test('total must be 9', () {
      final r = validateContent(make(l1: 4, l2: 3, l3: 3));
      expect(r.ok, isFalse);
      expect(r.errors.any((e) => e.contains('总数')), isTrue);
    });

    test('unclassified capped at 2', () {
      final ok = validateContent(make(unclassified: 2));
      expect(ok.ok, isTrue, reason: ok.errors.join('; '));
      final bad = validateContent(make(unclassified: 3));
      expect(bad.ok, isFalse);
    });

    test('word mismatch detected', () {
      final c = make();
      final r = validateContent(
        GeneratedWordContent(
          word: 'walk',
          senses: c.senses,
          unclassifiedExamples: c.unclassifiedExamples,
          phrases: c.phrases,
        ),
        expectWord: 'run',
      );
      expect(r.ok, isFalse);
    });
  });

  group('FRE / progression', () {
    test('short simple sentence scores higher than long complex', () {
      final simple = freScore('I run every morning.');
      final complex = freScore(
        'Having run the length of the corridor, he collapsed breathless against the door, gasping for air and clutching his chest.',
      );
      expect(simple, greaterThan(complex));
    });

    test('validation requires L1 > L2 > L3', () {
      final content = GeneratedWordContent(
        word: 'x',
        senses: [
          Sense(
            pos: 'v.',
            meaning: 'm',
            examples: [
              ex(1, 'I run.'),
              ex(1, 'She walks.'),
              ex(1, 'We eat rice.'),
              ex(2, 'He said that he would go to the store on Sunday.'),
              ex(
                2,
                'The dog that barked loudly was sleeping under the old wooden table in the kitchen.',
              ),
              ex(
                2,
                'Although the weather was cold and rainy, we decided to continue our long walk along the river.',
              ),
              ex(
                3,
                'Having run the length of the corridor, he collapsed breathless against the door, gasping for air.',
              ),
              ex(
                3,
                'The committee, having deliberated extensively, concluded that the proposal should be implemented immediately.',
              ),
              ex(
                3,
                'While the storm raged outside, the children, exhausted from their journey, slept peacefully in the old cabin.',
              ),
            ],
          ),
        ],
      );
      final r = validateProgression(content);
      expect(r.ok, isTrue, reason: r.errors.join('; '));
    });
  });
}
