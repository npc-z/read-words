import 'package:flutter_test/flutter_test.dart';
import 'package:read_words/import/parser.dart';

void main() {
  group('txt parser', () {
    test('plain words only', () {
      final r = parseTxt('apple\nbanana\ncherry\n');
      expect(r.words, ['apple', 'banana', 'cherry']);
      expect(r.skipped, 0);
    });

    test('tab-separated word+meaning', () {
      final r = parseTxt('apple\t苹果\nbanana\t香蕉\n');
      expect(r.words, ['apple', 'banana']);
      expect(r.meanings['apple'], '苹果');
    });

    test('comma-separated word+meaning', () {
      final r = parseTxt('apple,苹果\nbanana,香蕉\n');
      expect(r.meanings['apple'], '苹果');
    });

    test('space-separated word+meaning with multiple spaces', () {
      final r = parseTxt('apple  苹果\nbanana  香蕉\n');
      expect(r.meanings['apple'], '苹果');
    });

    test('drops empty lines, comments, BOM, trims whitespace', () {
      final r = parseTxt('# comment\n\n  apple  \n!bang\n');
      expect(r.words, ['apple']);
      expect(r.skipped, 2);
    });

    test('line without second column degrades to plain word', () {
      final r = parseTxt('apple\nbanana\t\ncherry something with spaces\n');
      expect(r.words, ['apple', 'banana', 'cherry something with spaces']);
      expect(r.meanings.containsKey('apple'), isFalse);
    });
  });

  group('markdown parser', () {
    test('headings as words, paragraph as meaning', () {
      final r = parseMarkdown('# apple\n\n红苹果,一种水果。\n\n## banana\n\n黄色的水果。\n');
      expect(r.words, ['apple', 'banana']);
      expect(r.meanings['apple'], contains('一种水果'));
    });

    test('list items as words', () {
      final r = parseMarkdown('- apple\n- banana\n');
      expect(r.words, ['apple', 'banana']);
    });

    test('no headings falls back to line splitting', () {
      final r = parseMarkdown('apple\nbanana\n');
      expect(r.words, ['apple', 'banana']);
    });
  });

  group('csv parser', () {
    test('header with word/meaning columns', () {
      final r = parseDelimited('word,meaning\napple,苹果\nbanana,香蕉\n');
      expect(r.words, ['apple', 'banana']);
      expect(r.meanings['apple'], '苹果');
    });

    test('header detection with zh aliases', () {
      final r = parseDelimited('单词,释义\napple,苹果\n');
      expect(r.words, ['apple']);
      expect(r.meanings['apple'], '苹果');
    });

    test('no header falls back to first=word second=meaning', () {
      final r = parseDelimited('apple,苹果\nbanana,香蕉\n');
      expect(r.words, ['apple', 'banana']);
      expect(r.meanings['banana'], '香蕉');
    });

    test('detects tab-delimited', () {
      final r = parseDelimited('word\tmeaning\napple\t苹果\n');
      expect(r.words, ['apple']);
    });
  });

  group('phonetic column detection', () {
    test('extracts phonetic column when present', () {
      final r = parseDelimited('word,phonetic,meaning\napple,/ˈæpəl/,苹果\n');
      expect(r.phonetics['apple'], '/ˈæpəl/');
      expect(r.meanings['apple'], '苹果');
    });
  });
}
