/// 生成服务(§6 管线):单词生成 + 重试 + 校验 + 落库。
library;

import 'dart:async';
import 'dart:convert';

import '../data/app_database.dart';
import '../data/repositories.dart';
import 'content.dart';
import 'deepseek_client.dart';
import 'prompt.dart';

/// 生成结果与失败信息(§6.3 失败清单)
class GenerationOutcome {
  const GenerationOutcome({this.word, this.failed = false, this.error});

  final String? word;
  final bool failed;
  final String? error;
}

/// 生成服务:调用 API → 校验(§4.2/§4.3)→ 落库。
class GenerationService {
  GenerationService({
    required this.client,
    required this.repositories,
    this.proficiency = Proficiency.cet,
    this.onProgress,
    Future<void> Function(Duration)? delayOverride,
  }) : _delay = delayOverride ?? Future<void>.delayed;

  final DeepSeekClient client;
  final Repositories repositories;
  final Proficiency proficiency;
  final Future<void> Function(Duration) _delay;

  /// 进度回调(用于任务控制台)
  final void Function(int done, int total, GenerationOutcome last)? onProgress;

  /// 生成一个词并落库。若词典素材存在则传入作为上下文(§5 拼接规则)。
  Future<GenerationOutcome> generateWord(
    int wordId, {
    String? dictionaryContext,
  }) async {
    final word = await repositories.wordById(wordId);
    if (word == null) {
      return const GenerationOutcome(failed: true, error: '词不存在');
    }
    await repositories.setWordStatus(wordId, WordStatus.generating);

    try {
      final result = await _generateWithRetries(
        word.headword,
        dictionaryContext,
      );

      // §4.2 硬性校验 + §6.4 软校验
      final hard = validateContent(result.content, expectWord: word.headword);
      if (!hard.ok) {
        return GenerationOutcome(
          word: word.headword,
          failed: true,
          error: hard.errors.join('; '),
        );
      }

      await repositories.saveMaterial(
        wordId,
        MaterialData(
          phoneticUk: result.content.phoneticUk,
          phoneticUs: result.content.phoneticUs,
          sensesJson: jsonEncode(result.content.toJson()['senses']),
          phrasesJson: jsonEncode(result.content.toJson()['phrases']),
          unclassifiedExamplesJson: jsonEncode(
            result.content.toJson()['unclassified_examples'],
          ),
          source: 'ai',
        ),
      );
      await repositories.setWordStatus(wordId, WordStatus.done);
      return GenerationOutcome(word: word.headword);
    } on GenerationApiException catch (e) {
      await repositories.setWordStatus(wordId, WordStatus.failed);
      return GenerationOutcome(
        word: word.headword,
        failed: true,
        error: e.message,
      );
    } catch (e) {
      await repositories.setWordStatus(wordId, WordStatus.failed);
      return GenerationOutcome(word: word.headword, failed: true, error: '$e');
    }
  }

  /// 按 §6.3 重试:网络错误指数退避重试 3 次(1s/4s/16s,共 4 次尝试);
  /// 校验错误重试 2 次(共 3 次尝试,属 prompt 质量问题退避无用)。
  Future<dynamic> _generateWithRetries(String word, String? context) async {
    GenerationApiException? lastTransient;
    const transientDelays = [
      Duration(seconds: 1),
      Duration(seconds: 4),
      Duration(seconds: 16),
    ];
    const validationAttempts = 3; // 初始 1 + 重试 2
    const transientAttempts = 4; // 初始 1 + 重试 3
    for (var attempt = 0; attempt < transientAttempts; attempt++) {
      if (attempt > 0) {
        await _delay(transientDelays[attempt - 1]);
      }
      try {
        return await client.generateWord(
          word: word,
          proficiency: proficiency,
          dictionaryContext: context,
        );
      } on GenerationApiException catch (e) {
        if (e.kind == GenerationErrorKind.transient) {
          lastTransient = e;
          continue; // 网络错误:最多 4 次尝试
        }
        if (e.kind == GenerationErrorKind.validation) {
          if (attempt < validationAttempts - 1) {
            await _delay(Duration.zero);
            continue; // 校验错误:最多 3 次尝试
          }
          rethrow;
        }
        rethrow; // permanent
      }
    }
    throw lastTransient!;
  }

  /// 批量生成(§6:队列消费端)。逐词生成,失败不阻塞。
  Future<List<GenerationOutcome>> generateBatch(
    List<int> wordIds, {
    void Function(int done, int total, GenerationOutcome last)? onProgress,
  }) async {
    final outcomes = <GenerationOutcome>[];
    for (var i = 0; i < wordIds.length; i++) {
      await repositories.setWordStatus(wordIds[i], WordStatus.queued);
      final o = await generateWord(wordIds[i]);
      outcomes.add(o);
      (onProgress ?? this.onProgress)?.call(i + 1, wordIds.length, o);
    }
    return outcomes;
  }
}

/// 构造默认生成服务:API Key 从设置读取(§12;未配置时为空串,调用会失败并提示)。
Future<GenerationService> buildGenerationService(
  Repositories repositories,
) async {
  final apiKey = await repositories.getSetting(SettingsKeys.apiKey) ?? '';
  return GenerationService(
    client: DeepSeekClient(apiKey: apiKey),
    repositories: repositories,
  );
}
