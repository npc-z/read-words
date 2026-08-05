/// 内容契约(规格书 §4):AI 生成内容的领域模型与 JSON schema 校验。
library;

/// 一个义项(§4.1 schema 的 senses[i])
class Sense {
  const Sense({
    required this.pos,
    required this.meaning,
    this.examples = const [],
  });

  final String pos;
  final String meaning;
  final List<Example> examples;

  Map<String, dynamic> toJson() => {
        'pos': pos,
        'meaning': meaning,
        'examples': examples.map((e) => e.toJson()).toList(),
      };

  static Sense? fromJson(Map<String, dynamic> json) {
    final pos = json['pos'];
    final meaning = json['meaning'];
    if (pos is! String || meaning is! String) return null;
    final examples = <Example>[];
    if (json['examples'] is List) {
      for (final e in json['examples'] as List) {
        if (e is! Map) continue;
        final ex = Example.fromJson(Map<String, dynamic>.from(e));
        if (ex != null) examples.add(ex);
      }
    }
    return Sense(pos: pos, meaning: meaning, examples: examples);
  }
}

/// 一条例句(level 1/2/3,en + zh 翻译)
class Example {
  const Example({required this.level, required this.en, required this.zh});

  final int level;
  final String en;
  final String zh;

  Map<String, dynamic> toJson() => {'level': level, 'en': en, 'zh': zh};

  static Example? fromJson(Map<String, dynamic> json) {
    final level = json['level'];
    final en = json['en'];
    final zh = json['zh'];
    if (level is! int || level < 1 || level > 3) return null;
    if (en is! String || en.isEmpty) return null;
    if (zh is! String || zh.isEmpty) return null;
    return Example(level: level, en: en, zh: zh);
  }
}

/// 常用短语(§4.1 schema 的 phrases[i])
class Phrase {
  const Phrase({required this.phrase, required this.en, required this.zh});

  final String phrase;
  final String en;
  final String zh;

  Map<String, dynamic> toJson() => {'phrase': phrase, 'en': en, 'zh': zh};

  static Phrase? fromJson(Map<String, dynamic> json) {
    final phrase = json['phrase'];
    final en = json['en'];
    final zh = json['zh'];
    if (phrase is! String || phrase.isEmpty) return null;
    if (en is! String || en.isEmpty) return null;
    if (zh is! String || zh.isEmpty) return null;
    return Phrase(phrase: phrase, en: en, zh: zh);
  }
}

/// 每词生成内容(§4.1)
class GeneratedWordContent {
  const GeneratedWordContent({
    required this.word,
    required this.senses,
    this.phrases = const [],
    this.unclassifiedExamples = const [],
    this.phoneticUk = '',
    this.phoneticUs = '',
  });

  final String word;
  final List<Sense> senses;
  final List<Phrase> phrases;
  final List<Example> unclassifiedExamples;
  final String phoneticUk;
  final String phoneticUs;

  Map<String, dynamic> toJson() => {
        'word': word,
        'phonetic': {
          if (phoneticUk.isNotEmpty) 'uk': phoneticUk,
          if (phoneticUs.isNotEmpty) 'us': phoneticUs,
        },
        'senses': senses.map((s) => s.toJson()).toList(),
        'phrases': phrases.map((p) => p.toJson()).toList(),
        'unclassified_examples': unclassifiedExamples.map((e) => e.toJson()).toList(),
      };

  static GeneratedWordContent? fromJson(Map<String, dynamic> json) {
    final word = json['word'];
    if (word is! String || word.isEmpty) return null;

    final senses = <Sense>[];
    if (json['senses'] is List) {
      for (final s in json['senses'] as List) {
        if (s is! Map) continue;
        final sense = Sense.fromJson(Map<String, dynamic>.from(s));
        if (sense != null) senses.add(sense);
      }
    }

    final phrases = <Phrase>[];
    if (json['phrases'] is List) {
      for (final p in json['phrases'] as List) {
        if (p is! Map) continue;
        final phrase = Phrase.fromJson(Map<String, dynamic>.from(p));
        if (phrase != null) phrases.add(phrase);
      }
    }

    final unclassified = <Example>[];
    if (json['unclassified_examples'] is List) {
      for (final e in json['unclassified_examples'] as List) {
        if (e is! Map) continue;
        final ex = Example.fromJson(Map<String, dynamic>.from(e));
        if (ex != null) unclassified.add(ex);
      }
    }

    var uk = '';
    var us = '';
    final phonetic = json['phonetic'];
    if (phonetic is Map) {
      uk = phonetic['uk'] is String ? phonetic['uk'] as String : '';
      us = phonetic['us'] is String ? phonetic['us'] as String : '';
    }

    return GeneratedWordContent(
      word: word,
      senses: senses,
      phrases: phrases,
      unclassifiedExamples: unclassified,
      phoneticUk: uk,
      phoneticUs: us,
    );
  }

  /// 全部例句(含未分类)
  List<Example> get allExamples => [
        for (final s in senses) ...s.examples,
        ...unclassifiedExamples,
      ];
}

/// 校验结果(§4.2 硬性约束 + §6.4 软校验)
class ValidationResult {
  const ValidationResult({required this.ok, this.errors = const []});

  final bool ok;
  final List<String> errors;
}

/// 内容契约校验(§4.2):
/// 1. 9 句恒定:L1×3 + L2×3 + L3×3(按 level 全局校验)
/// 2. 至少 7 句挂在具体 sense 下,最多 2 句 unclassified
/// 3. 词头一致
ValidationResult validateContent(GeneratedWordContent content, {String? expectWord}) {
  final errors = <String>[];

  if (expectWord != null && content.word.toLowerCase() != expectWord.toLowerCase()) {
    errors.add('词头不一致:期望 $expectWord,实际 ${content.word}');
  }

  if (content.senses.isEmpty) {
    errors.add('缺少义项(senses 为空)');
  }

  final counts = <int, int>{1: 0, 2: 0, 3: 0};
  for (final e in content.allExamples) {
    counts[e.level] = counts[e.level]! + 1;
  }
  for (final lvl in [1, 2, 3]) {
    final n = counts[lvl]!;
    if (n != 3) errors.add('L$lvl 例句数应为 3,实际 $n');
  }

  final total = content.allExamples.length;
  if (total != 9) errors.add('例句总数应为 9,实际 $total');

  final attached = total - content.unclassifiedExamples.length;
  if (attached < 7) errors.add('至少 7 句应挂在义项下,实际 $attached');

  if (content.phrases.length > 4) errors.add('短语最多 4 个,实际 ${content.phrases.length}');

  return ValidationResult(ok: errors.isEmpty, errors: errors);
}

/// FRE 可读性软校验(§6.4):L1 > L2 > L3。
/// FRE = 206.835 - 1.015*(词数/句数) - 84.6*(音节数/词数)
double freScore(String sentence) {
  final words = sentence
      .split(RegExp(r'\s+'))
      .where((w) => RegExp(r'[a-zA-Z]').hasMatch(w))
      .toList();
  if (words.isEmpty) return 0;
  var syllables = 0;
  for (final w in words) {
    final lower = w.toLowerCase();
    var count = RegExp(r'[aeiouy]+').allMatches(lower).length;
    if (lower.endsWith('e')) count--;
    if (lower.endsWith('y') && lower.length > 3) count--;
    if (count < 1) count = 1;
    syllables += count;
  }
  return 206.835 - 1.015 * (words.length / 1) - 84.6 * (syllables / words.length);
}

/// 分层递进软校验:L1 平均 FRE > L2 平均 FRE > L3 平均 FRE(§4.3)。
ValidationResult validateProgression(GeneratedWordContent content) {
  final byLevel = <int, List<Example>>{1: [], 2: [], 3: []};
  for (final e in content.allExamples) {
    byLevel[e.level]!.add(e);
  }
  double avg(int lvl) {
    final list = byLevel[lvl]!;
    if (list.isEmpty) return double.nan;
    return list.map((e) => freScore(e.en)).reduce((a, b) => a + b) / list.length;
  }
  final errors = <String>[];
  final a1 = avg(1), a2 = avg(2), a3 = avg(3);
  if (!(a1 > a2)) errors.add('FRE 递进失败:L1(${a1.toStringAsFixed(1)}) 应大于 L2(${a2.toStringAsFixed(1)})');
  if (!(a2 > a3)) errors.add('FRE 递进失败:L2(${a2.toStringAsFixed(1)}) 应大于 L3(${a3.toStringAsFixed(1)})');
  return ValidationResult(ok: errors.isEmpty, errors: errors);
}
