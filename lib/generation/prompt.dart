/// Prompt 模板(规格书 §4.3/§4.4):按用户水平生成 9 句 3 层例句 + 释义 + 短语。
library;

/// 用户水平(§2 首次启动选择)
enum Proficiency {
  gaokao('高考', 'BNC 前 5000 及 zk/gk 标签词', '释义用词简单,每条释义附 1 个近义说明'),
  cet('四六级', 'BNC 前 12000 及 cet4/cet6 标签词', '标准英文释义'),
  tem('专四专八', 'BNC 前 30000 及 gre/toefl/ielts 标签词', '精炼学术化释义,区分细微差别');

  const Proficiency(this.label, this.vocabularyRange, this.definitionStyle);

  final String label;
  final String vocabularyRange;
  final String definitionStyle;
}

/// 组装生成 prompt(§4.4:词频范围 + 基准复杂度 + 释义风格作为参数写入 prompt)。
String buildGenerationPrompt({
  required String word,
  required Proficiency proficiency,
  String? dictionaryContext,
}) {
  final context = dictionaryContext == null || dictionaryContext.isEmpty
      ? '无'
      : dictionaryContext;
  return '''
你是一位专业的英语学习内容生成器。为单词 "$word" 生成分层学习素材。目标学习者的英语水平:${proficiency.label}。

## 词典素材(来自用户的词典,可参考,但不要原样照抄词典释义)
$context

## 输出要求(严格遵守)

生成 JSON,结构如下:
{
  "word": "$word",
  "phonetic": { "uk": "英式音标(若无把握可留空)", "us": "美式音标(尽力而为,可留空)" },
  "senses": [
    {
      "pos": "v.",
      "meaning": "该义项的英文释义",
      "examples": [
        { "level": 1, "en": "例句英文", "zh": "例句中文翻译" }
      ]
    }
  ],
  "phrases": [
    { "phrase": "常用短语", "en": "短语例句", "zh": "短语例句中文翻译" }
  ],
  "unclassified_examples": []
}

## 硬性规则

1. **例句总数必须为 9 句**:level 1 恰好 3 句,level 2 恰好 3 句,level 3 恰好 3 句。
2. 例句按义项分布:主要义项分到更多例句;至少 7 句必须挂在 senses 的 examples 里,最多 2 句(习语化用法)可放入 unclassified_examples。
3. 例句是释义的延续:每条例句的语义必须属于它所在的义项。
4. 词性覆盖:单词有几个常用词性就生成几个 sense(如 run 有 v./n.)。
5. 短语 1~4 个,按单词实际搭配多寡决定;每个短语配 1 条例句 + 中文翻译;短语本身不翻译。
6. 例句和短语例句必须有中文翻译(zh),用于学习者的理解确认。
7. 释义必须用英文书写,不得夹带中文。中文翻译只出现在例句的 zh 字段。

## 难度分层(层间难度必须真实递进)

- **level 1**:简单句(主谓宾/主系表,至多 1 个并列);目标词之外的用词限制在:${proficiency.vocabularyRange};长度 5~10 词。
- **level 2**:可含从句(宾语从句/定语从句)、时间地点状语;可引入目标词的引申义与常见搭配;长度 10~18 词。
- **level 3**:复合句(多从句嵌套、非谓语、倒装、虚拟语气等);书面语、习语化表达、生僻搭配;长度 18~30 词。

## 释义风格

${proficiency.definitionStyle}

只输出 JSON,不要输出任何其他文字、注释或 markdown 代码块标记。
''';
}
