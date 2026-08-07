/// 例句池合并与选取(§6.3 增量积累):跨多次响应的例句去重合并,
/// 最大化利用每次 AI 响应;不足时继续积累,过度产出时裁剪。
library;

import 'content.dart';

/// 合并 [attempts](词头均已通过校验的响应)的例句池并选取 9 句(每层 3 句)。
///
/// - 例句按英文文本规范化去重(小写、折叠空白),跨响应只留一条;
/// - 义项按 pos+meaning(规范化)匹配:重复义项的例句归并,独有义项追加;
///   同义项措辞略有差异时视为不同义项(各自保留例句,不影响选取);
/// - 选取规则:按响应顺序逐义项取例句(义项覆盖优先),每层凑满 3 句;
///   义项内不足时用 unclassified 补(全局至多 2 句,保证 ≥7 句挂义项);
/// - 池子不足(某层凑不满 3 句)返回 null;
/// - 过度产出被裁剪到每层恰好 3 句;短语按出现顺序去重,最多 4 个。
GeneratedWordContent? mergeAndSelect(List<GeneratedWordContent> attempts) {
  if (attempts.isEmpty) return null;

  // 1. 合并:义项归并 + 例句/短语去重
  final senses = <Sense>[];
  final unclassified = <Example>[];
  final phrases = <Phrase>[];
  final seenEn = <String>{};
  final seenPhrases = <String>{};

  for (final a in attempts) {
    for (final s in a.senses) {
      var target = _findSense(senses, s);
      if (target == null) {
        target = Sense(pos: s.pos, meaning: s.meaning, examples: []);
        senses.add(target);
      }
      target.examples.addAll(_dedupeExamples(s.examples, seenEn));
    }
    unclassified.addAll(_dedupeExamples(a.unclassifiedExamples, seenEn));
    for (final p in a.phrases) {
      final key = _norm(p.phrase);
      if (key.isNotEmpty && seenPhrases.add(key)) phrases.add(p);
    }
  }

  // 2. 选取:每层恰好 3 句;按义项轮转取句(义项覆盖优先——主要义项在前,
  // 每轮每个义项取 1 条,保证多义项都有例句);义项内不足用 unclassified
  // 补(全局至多 2 句,保证 ≥7 句挂义项)
  final selected = <int, List<Example>>{1: [], 2: [], 3: []};
  final selectedUnclassified = <Example>[];
  var unclassifiedBudget = 2;
  for (final lvl in [1, 2, 3]) {
    final bySense = [
      for (final s in senses) s.examples.where((e) => e.level == lvl).toList(),
    ];
    var round = 0;
    while (selected[lvl]!.length < 3) {
      var tookAny = false;
      for (final list in bySense) {
        if (round < list.length) {
          selected[lvl]!.add(list[round]);
          tookAny = true;
          if (selected[lvl]!.length >= 3) break;
        }
      }
      if (!tookAny) break;
      round++;
    }
    if (selected[lvl]!.length < 3) {
      for (final e in unclassified) {
        if (e.level != lvl || unclassifiedBudget <= 0) continue;
        selected[lvl]!.add(e);
        selectedUnclassified.add(e);
        unclassifiedBudget--;
        if (selected[lvl]!.length >= 3) break;
      }
    }
    if (selected[lvl]!.length < 3) return null; // 池子不足
  }

  // 3. 重建:只保留被选中的例句;无例句的义项丢弃
  final selectedSet = {for (final lvl in [1, 2, 3]) ...selected[lvl]!};
  final finalSenses = [
    for (final s in senses)
      if (s.examples.any(selectedSet.contains))
        Sense(
          pos: s.pos,
          meaning: s.meaning,
          examples: s.examples.where(selectedSet.contains).toList(),
        ),
  ];
  if (finalSenses.isEmpty) return null; // 安全网:例句全为 unclassified

  final first = attempts.first;
  return GeneratedWordContent(
    word: first.word,
    phoneticUk: first.phoneticUk,
    phoneticUs: first.phoneticUs,
    senses: finalSenses,
    phrases: phrases.take(4).toList(),
    unclassifiedExamples: selectedUnclassified.take(2).toList(),
  );
}

/// 池子数量反馈(§6.3):与 validateContent 相同措辞,按去重后的池子统计,
/// 供反馈式重试的 prompt 使用。
List<String> countErrors(List<GeneratedWordContent> attempts) {
  final seen = <String>{};
  final counts = <int, int>{1: 0, 2: 0, 3: 0};
  var total = 0;
  for (final a in attempts) {
    for (final e in _dedupeExamples(a.allExamples, seen)) {
      counts[e.level] = counts[e.level]! + 1;
      total++;
    }
  }
  final errors = <String>[];
  for (final lvl in [1, 2, 3]) {
    final n = counts[lvl]!;
    if (n < 3) errors.add('L$lvl 例句数应为 3,实际 $n');
  }
  if (total < 9) errors.add('例句总数应为 9,实际 $total');
  return errors;
}

/// 义项匹配键:pos + meaning(规范化)
String _senseKey(Sense s) =>
    '${s.pos.trim().toLowerCase()}|${s.meaning.trim().toLowerCase()}';

Sense? _findSense(List<Sense> senses, Sense s) {
  final key = _senseKey(s);
  for (final x in senses) {
    if (_senseKey(x) == key) return x;
  }
  return null;
}

/// 例句去重(按 [seen] 集合跳过已见文本);供合并与统计共用
List<Example> _dedupeExamples(Iterable<Example> source, Set<String> seen) {
  final out = <Example>[];
  for (final e in source) {
    final key = _norm(e.en);
    if (key.isEmpty || !seen.add(key)) continue;
    out.add(e);
  }
  return out;
}

/// 例句/短语去重键:小写、折叠空白
String _norm(String s) => s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
