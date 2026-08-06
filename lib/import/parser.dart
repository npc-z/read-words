/// 导入解析层(规格书 §7.1):探测式解析,支持 txt / markdown / csv / excel。
library;

/// 解析结果:词表 + 可选的释义/音标列(供预览确认界面展示与纠正)
class ParseResult {
  const ParseResult({
    required this.words,
    this.meanings = const {},
    this.phonetics = const {},
    this.skipped = 0,
  });

  final List<String> words;
  final Map<String, String> meanings;
  final Map<String, String> phonetics;
  final int skipped;

  int get count => words.length;
}

/// 单词类行:提取头部单词(小写、去空白)。
String? _cleanWord(String s) {
  final w = s.trim();
  if (w.isEmpty) return null;
  return w.toLowerCase();
}

bool _isComment(String line) {
  return line.trimLeft().startsWith('#') || line.trimLeft().startsWith('!');
}

/// 把一行拆成 [word, rest] 两段:优先制表符,其次逗号,最后连续空格。
/// 拆不出第二段时返回仅含单词的结果。
List<String> _splitLine(String line) {
  final trimmed = line.trim();
  for (final sep in ['\t', ',']) {
    final parts = trimmed.split(sep);
    if (parts.length >= 2 && parts[1].trim().isNotEmpty) {
      return [parts[0].trim(), parts.sublist(1).join(sep).trim()];
    }
  }
  final m = RegExp(r'^(\S+)\s{2,}(\S.*)$').firstMatch(trimmed);
  if (m != null) return [m.group(1)!, m.group(2)!.trim()];
  return [trimmed];
}

/// txt 解析:按行 + 分隔符探测(§7.1)。
/// - 含第二列 → 单词-释义;否则降级为纯单词
/// - BOM/空行/`#` `!` 注释行跳过
ParseResult parseTxt(String content, {String encoding = 'utf-8'}) {
  final text = content.startsWith('\uFEFF') ? content.substring(1) : content;
  final words = <String>[];
  final meanings = <String, String>{};
  var skipped = 0;

  for (final raw in text.split('\n')) {
    final line = raw.trim();
    if (line.isEmpty) continue;
    if (_isComment(line)) {
      skipped++;
      continue;
    }
    final parts = _splitLine(line);
    final word = _cleanWord(parts[0]);
    if (word == null) {
      skipped++;
      continue;
    }
    words.add(word);
    if (parts.length > 1) meanings[word] = parts[1];
  }
  return ParseResult(words: words, meanings: meanings, skipped: skipped);
}

/// markdown 解析(§7.1):`# 标题` 作词头,正文段落作释义;`- ` 列表项作词条。
/// 无标题时回退为按行拆词。
ParseResult parseMarkdown(String content) {
  final lines = content.split('\n');
  final words = <String>[];
  final meanings = <String, String>{};
  String? currentWord;
  final buffer = <String>[];

  void flush() {
    final w = currentWord;
    if (w != null && buffer.isNotEmpty) {
      meanings[w] = buffer.join(' ').trim();
    }
    buffer.clear();
  }

  var skipped = 0;
  for (final raw in lines) {
    final line = raw.trim();
    if (line.isEmpty) {
      skipped++;
      continue;
    }
    final heading = RegExp(r'^(#{1,6})\s+(.+)$').firstMatch(line);
    if (heading != null) {
      flush();
      currentWord = _cleanWord(heading.group(2)!);
      if (currentWord != null) {
        words.add(currentWord);
      } else {
        currentWord = null;
      }
      continue;
    }
    final listItem = RegExp(r'^[-*]\s+(.+)$').firstMatch(line);
    if (listItem != null && currentWord == null) {
      final w = _cleanWord(listItem.group(1)!);
      if (w != null) words.add(w);
      continue;
    }
    if (listItem != null) {
      buffer.add(listItem.group(1)!.trim());
      continue;
    }
    if (currentWord != null) {
      buffer.add(line);
    } else if (!_isComment(line)) {
      final w = _cleanWord(line);
      if (w != null && RegExp(r"^[a-zA-Z][a-zA-Z0-9'\-]*$").hasMatch(w)) {
        words.add(w);
      }
    }
  }
  flush();
  if (words.isEmpty) return parseTxt(content);
  return ParseResult(words: words, meanings: meanings, skipped: skipped);
}

/// 通用定界文本(csv / tsv)解析(§7.1):
/// - 首行表头自适应:识别 word/单词/headword、meaning/释义、phonetic/音标
/// - 无表头 → 第一列词、第二列释义
ParseResult parseDelimited(String content) {
  final text = content.startsWith('\uFEFF') ? content.substring(1) : content;
  final delim = _detectDelimiter(text);
  final rows = _parseRows(text, delim);
  if (rows.isEmpty) return const ParseResult(words: [], skipped: 0);

  final header = rows.first.map((c) => c.trim().toLowerCase()).toList();
  var wordIdx = header.indexWhere(
    (h) => _matchesAny(h, ['word', '单词', 'headword', '词头', '词汇']),
  );
  final meaningIdx = header.indexWhere(
    (h) => _matchesAny(h, ['meaning', '释义', 'translation', '翻译', '中文']),
  );
  final phoneticIdx = header.indexWhere(
    (h) => _matchesAny(h, ['phonetic', '音标', 'ipa']),
  );
  final isHeader = wordIdx >= 0 || meaningIdx >= 0 || phoneticIdx >= 0;
  if (!isHeader) {
    wordIdx = 0;
  }
  final effMeaningIdx = isHeader ? meaningIdx : 1;

  final words = <String>[];
  final meanings = <String, String>{};
  final phonetics = <String, String>{};
  var skipped = 0;

  for (final row in isHeader ? rows.skip(1) : rows) {
    if (row.length <= wordIdx) {
      skipped++;
      continue;
    }
    final word = _cleanWord(row[wordIdx]);
    if (word == null || RegExp(r'^[0-9.,]+$').hasMatch(word)) {
      skipped++;
      continue;
    }
    words.add(word);
    if (effMeaningIdx >= 0 && row.length > effMeaningIdx) {
      meanings[word] = row[effMeaningIdx].trim();
    }
    if (phoneticIdx >= 0 && row.length > phoneticIdx) {
      phonetics[word] = row[phoneticIdx].trim();
    }
  }
  return ParseResult(
    words: words,
    meanings: meanings,
    phonetics: phonetics,
    skipped: skipped,
  );
}

bool _matchesAny(String s, List<String> candidates) => candidates.contains(s);

String _detectDelimiter(String text) {
  final firstLine = text.split('\n').first;
  final tabs = firstLine.split('\t').length;
  final commas = firstLine.split(',').length;
  return tabs > commas ? '\t' : ',';
}

List<List<String>> _parseRows(String text, String delim) {
  return text
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .map((l) => l.split(delim).map((c) => c.trim()).toList())
      .toList();
}
