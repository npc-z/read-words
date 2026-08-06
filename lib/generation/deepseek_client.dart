/// DeepSeek(OpenAI 兼容)API 客户端(§6)。
library;

import 'dart:convert';
import 'package:dio/dio.dart';
import '../generation/content.dart';
import '../generation/prompt.dart';

/// API 调用异常(§6.3:网络错误与结构错误区分重试策略)
class GenerationApiException implements Exception {
  const GenerationApiException(this.kind, this.message);

  final GenerationErrorKind kind;
  final String message;

  @override
  String toString() => 'GenerationApiException($kind): $message';
}

enum GenerationErrorKind {
  /// 网络/超时/限流(退避重试 3 次)
  transient,

  /// 结构校验失败(重试 2 次)
  validation,

  /// 4xx 不可重试错误
  permanent,
}

/// 一次生成的结果
class GenerationResult {
  const GenerationResult({required this.content, required this.rawJson});

  final GeneratedWordContent content;
  final String rawJson;
}

class DeepSeekClient {
  DeepSeekClient({
    required this.apiKey,
    this.baseUrl = 'https://api.deepseek.com',
    this.model = 'deepseek-chat',
    this.connectTimeout = const Duration(seconds: 10),
    this.receiveTimeout = const Duration(seconds: 10),
    this.sendTimeout = const Duration(seconds: 10),
    Dio? dio,
  }) : _dio = (dio ?? Dio())
          ..options.connectTimeout = connectTimeout
          ..options.receiveTimeout = receiveTimeout
          ..options.sendTimeout = sendTimeout;

  final String apiKey;
  final String baseUrl;
  final String model;

  /// 超时(§6.3):请求挂起(网络/服务端无响应)不能永久阻塞队列 worker,
  /// 超时按 transient 处理走退避重试。Web 端合计为 connect+receive。
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final Duration sendTimeout;

  final Dio _dio;

  /// 生成单个单词的学习内容(§4)。非流式单次调用。
  /// [feedback] 为上次输出校验失败清单(§6.3 反馈式重试),追加进 prompt。
  Future<GenerationResult> generateWord({
    required String word,
    required Proficiency proficiency,
    String? dictionaryContext,
    String? feedback,
  }) async {
    final prompt = buildGenerationPrompt(
      word: word,
      proficiency: proficiency,
      dictionaryContext: dictionaryContext,
      feedback: feedback,
    );
    final text = await _chat(prompt);
    final json = _extractJson(text);
    final content = GeneratedWordContent.fromJson(json);
    if (content == null) {
      throw const GenerationApiException(
        GenerationErrorKind.validation,
        'JSON 结构不符合内容契约',
      );
    }
    return GenerationResult(content: content, rawJson: text);
  }

  Future<String> _chat(String prompt) async {
    try {
      final resp = await _dio.post(
        '$baseUrl/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': model,
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.7,
          'response_format': {'type': 'json_object'},
        },
      );
      final data = resp.data as Map<String, dynamic>;
      final choices = data['choices'] as List?;
      if (choices == null || choices.isEmpty) {
        throw const GenerationApiException(
          GenerationErrorKind.validation,
          'API 响应缺少 choices',
        );
      }
      final message = choices.first['message'] as Map<String, dynamic>?;
      final content = message?['content'] as String?;
      if (content == null || content.isEmpty) {
        throw const GenerationApiException(
          GenerationErrorKind.validation,
          'API 响应缺少内容',
        );
      }
      return content;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status != null && status >= 400 && status < 500) {
        if (status == 429) {
          throw GenerationApiException(
            GenerationErrorKind.transient,
            '限流(429):${e.message}',
          );
        }
        throw GenerationApiException(
          GenerationErrorKind.permanent,
          'API 错误 $status:${e.message}',
        );
      }
      throw GenerationApiException(
        GenerationErrorKind.transient,
        '网络错误:${e.message}',
      );
    }
  }

  /// 从模型输出中提取 JSON(容忍 ```json 围栏等噪音)。
  Map<String, dynamic> _extractJson(String text) {
    final m = RegExp(r'```(?:json)?\s*([\s\S]*?)```').firstMatch(text);
    final candidate = m != null ? m.group(1)! : text;
    final start = candidate.indexOf('{');
    final end = candidate.lastIndexOf('}');
    if (start < 0 || end <= start) {
      throw const GenerationApiException(
        GenerationErrorKind.validation,
        '响应中未找到 JSON 对象',
      );
    }
    try {
      return jsonDecode(candidate.substring(start, end + 1))
          as Map<String, dynamic>;
    } catch (_) {
      throw const GenerationApiException(
        GenerationErrorKind.validation,
        'JSON 解析失败',
      );
    }
  }
}
