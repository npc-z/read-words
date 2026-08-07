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
  /// 校验错误重试 2 次(共 3 次尝试)——结构错误直接重试,§4.2 内容契约
  /// 错误带失败清单反馈重试(让模型按反馈修正);最终仍失败抛异常。
  Future<dynamic> _generateWithRetries(String word, String? context) async {
    GenerationApiException? lastTransientError;
    var lastAttemptWasTransient = false;
    String? feedback;
    const transientDelays = [
      Duration(seconds: 1),
      Duration(seconds: 4),
      Duration(seconds: 16),
    ];
    const validationAttempts = 3; // 初始 1 + 重试 2
    const transientAttempts = 4; // 初始 1 + 重试 3
    for (var attempt = 0; attempt < transientAttempts; attempt++) {
      if (attempt > 0) {
        // 网络错误退避;校验重试不等待
        await _delay(
          lastAttemptWasTransient ? transientDelays[attempt - 1] : Duration.zero,
        );
      }
      try {
        final result = await client.generateWord(
          word: word,
          proficiency: proficiency,
          dictionaryContext: context,
          feedback: feedback,
        );
        final hard = validateContent(result.content, expectWord: word);
        if (!hard.ok) {
          feedback = hard.errors.join('; ');
          lastAttemptWasTransient = false;
          if (attempt < validationAttempts - 1) {
            continue; // 带反馈重试
          }
          throw GenerationApiException(
            GenerationErrorKind.validation,
            hard.errors.join('; '),
          );
        }
        return result;
      } on GenerationApiException catch (e) {
        if (e.kind == GenerationErrorKind.transient) {
          lastAttemptWasTransient = true;
          lastTransientError = e;
          continue; // 网络错误:最多 4 次尝试
        }
        lastAttemptWasTransient = false;
        if (e.kind == GenerationErrorKind.validation &&
            attempt < validationAttempts - 1) {
          continue; // 结构校验错误:最多 3 次尝试
        }
        rethrow; // permanent / 校验用尽
      }
    }
    throw lastTransientError!;
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

/// 构造默认生成服务:API Key 与模型名从设置读取(§12;Key 未配置时为空串,
/// 调用会失败并提示;模型空白回退默认)。
Future<GenerationService> buildGenerationService(
  Repositories repositories,
) async {
  final s = await repositories.settings();
  return GenerationService(
    client: DeepSeekClient(apiKey: s.apiKey, model: s.model),
    repositories: repositories,
  );
}
