import 'package:flutter_test/flutter_test.dart';
import 'package:read_words/generation/prompt.dart';

void main() {
  String prompt({String? feedback}) => buildGenerationPrompt(
        word: 'run',
        proficiency: Proficiency.cet,
        feedback: feedback,
      );

  test('prompt explicitly requires exactly 3 examples per level, 9 total', () {
    final p = prompt();

    expect(p, contains('例句总数恰好 9 条'));
    expect(p, contains('level 1 恰好 3 条'));
    expect(p, contains('level 2 恰好 3 条'));
    expect(p, contains('level 3 恰好 3 条'));
    // 明确禁止「每义项各配 3 条」的常见误读(该误读曾导致 18 条输出)
    expect(p, contains('严禁'));
    // 自查段已移除,不残留(数量约束由硬性规则 1 + 服务端增量合并兜底)
    expect(p, isNot(contains('输出前自查')));
  });

  test('feedback section appended when validation failed', () {
    final p = prompt(feedback: 'L1 例句数应为 3,实际 6;例句总数应为 9,实际 18');

    expect(p, contains('## 上次输出校验失败(必须修正)'));
    expect(p, contains('L1 例句数应为 3,实际 6'));
  });
}
