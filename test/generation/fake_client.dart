import 'dart:async';
import 'dart:convert';

import 'package:read_words/generation/content.dart';
import 'package:read_words/generation/deepseek_client.dart';
import 'package:read_words/generation/prompt.dart';

/// 可控的假客户端:返回合法 9 句内容;可配置抛错、内容覆盖、gate 阻塞。
class FakeClient extends DeepSeekClient {
  FakeClient({Completer<void>? gate}) : super(apiKey: 'fake') {
    if (gate != null) gates.add(gate);
  }

  String? requestedWord;
  int callCount = 0;

  /// 每次调用按序消费的 gate 列表;为空不阻塞(用于观察并发中间态)
  final List<Completer<void>> gates = [];

  /// 待返回的原始响应;null 表示抛错
  String? rawResponse;
  GenerationApiException? errorToThrow;
  Map<String, dynamic>? contentOverride;

  @override
  Future<GenerationResult> generateWord({
    required String word,
    required Proficiency proficiency,
    String? dictionaryContext,
  }) async {
    callCount++;
    requestedWord = word;
    if (gates.isNotEmpty) {
      final g = gates.removeAt(0);
      await g.future;
    }
    if (errorToThrow != null) throw errorToThrow!;
    final json = contentOverride ??
        {
          'word': word,
          'phonetic': {'uk': '/x/', 'us': '/x/'},
          'senses': [
            {
              'pos': 'v.',
              'meaning': 'm',
              'examples': [
                {'level': 1, 'en': 'a1', 'zh': 'z1'},
                {'level': 1, 'en': 'a2', 'zh': 'z2'},
                {'level': 1, 'en': 'a3', 'zh': 'z3'},
                {'level': 2, 'en': 'b1', 'zh': 'z4'},
                {'level': 2, 'en': 'b2', 'zh': 'z5'},
                {'level': 2, 'en': 'b3', 'zh': 'z6'},
                {'level': 3, 'en': 'c1', 'zh': 'z7'},
                {'level': 3, 'en': 'c2', 'zh': 'z8'},
                {'level': 3, 'en': 'c3', 'zh': 'z9'},
              ],
            },
          ],
          'phrases': [],
          'unclassified_examples': [],
        };
    final content = GeneratedWordContent.fromJson(json);
    return GenerationResult(content: content!, rawJson: jsonEncode(json));
  }
}
