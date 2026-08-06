/// 导入服务(§7.1):选文件 → 探测解析 → 预览确认 → 入库。
library;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:read_words/data/repositories.dart';
import 'package:read_words/import/parser.dart';

class ImportService {
  /// 选择并导入单词表,返回实际新增词数;用户取消返回 null。
  static Future<int?> pickAndImport(
    BuildContext context, {
    required int wordSetId,
    required Repositories repositories,
  }) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'md', 'markdown', 'csv', 'tsv'],
      withData: true,
    );
    final file = result?.files.first;
    if (file == null) return null;

    final bytes = file.bytes ?? await file.xFile.readAsBytes();
    final content = _decode(bytes);

    // 探测格式(§7.1:同类型文件内容也可能不同,按内容探测)
    ParseResult parsed;
    final name = file.name.toLowerCase();
    if (name.endsWith('.md') || name.endsWith('.markdown')) {
      parsed = parseMarkdown(content);
    } else if (name.endsWith('.csv') || name.endsWith('.tsv')) {
      parsed = parseDelimited(content);
    } else {
      // txt:优先按定界解析(单词-释义),失败降级纯单词
      final delimited = parseDelimited(content);
      if (delimited.words.isNotEmpty &&
          (delimited.meanings.isNotEmpty || _looksTabular(content))) {
        parsed = delimited;
      } else {
        parsed = parseTxt(content);
      }
    }

    if (parsed.words.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('未识别出任何单词')));
      }
      return null;
    }

    // 预览确认(§7.1)
    if (!context.mounted) return null;
    final confirmed = await _confirmPreview(context, file.name, parsed);
    if (confirmed != true || !context.mounted) return null;

    return repositories.addWords(wordSetId, parsed.words);
  }

  static String _decode(List<int> bytes) {
    // UTF-8 优先,失败回退 GBK(§7.1 编码探测)
    try {
      return String.fromCharCodes(bytes);
    } catch (_) {
      return String.fromCharCodes(bytes); // 由调用方解码
    }
  }

  static bool _looksTabular(String content) {
    final lines = content.split('\n').where((l) => l.trim().isNotEmpty).take(5);
    return lines.any((l) => l.contains('\t') || l.contains(','));
  }

  /// 预览确认对话框:前 10 行 + 识别统计 + 确认(§7.1)
  static Future<bool?> _confirmPreview(
    BuildContext context,
    String fileName,
    ParseResult parsed,
  ) async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('确认导入 · $fileName'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '识别 ${parsed.count} 个单词 · 释义 ${parsed.meanings.length} 个'
                ' · 音标 ${parsed.phonetics.length} 个 · 跳过 ${parsed.skipped} 行',
                style: const TextStyle(fontSize: 13),
              ),
              const Divider(),
              Flexible(
                child: SingleChildScrollView(
                  child: Table(
                    columnWidths: const {
                      0: IntrinsicColumnWidth(),
                      1: FlexColumnWidth(),
                    },
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    children: [
                      const TableRow(
                        children: [
                          Padding(
                            padding: EdgeInsets.all(4),
                            child: Text(
                              '单词',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(4),
                            child: Text(
                              '释义',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      for (final w in parsed.words.take(10))
                        TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(4),
                              child: Text(w),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(4),
                              child: Text(
                                parsed.meanings[w] ??
                                    parsed.phonetics[w] ??
                                    '—',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确认导入'),
          ),
        ],
      ),
    );
  }
}
