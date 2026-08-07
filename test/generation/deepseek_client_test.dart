import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:read_words/generation/deepseek_client.dart';
import 'package:read_words/generation/prompt.dart';

/// 捕获请求体的假适配器(用于断言请求参数)
class _CaptureAdapter implements HttpClientAdapter {
  final List<Map<String, dynamic>> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (requestStream != null) {
      final bytes = await requestStream
          .fold<List<int>>([], (acc, chunk) => acc..addAll(chunk));
      requests.add(jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>);
    }
    return ResponseBody.fromString(
      jsonEncode({
        'choices': [
          {
            'message': {
              'role': 'assistant',
              'content': '{"word":"run"}',
            },
          },
        ],
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('default model is deepseek-v4-flash', () {
    expect(DeepSeekClient(apiKey: 'k').model, 'deepseek-v4-flash');
  });

  test('default timeouts are 20s each (web total 40s)', () {
    expect(DeepSeekClient.defaultConnectTimeout, const Duration(seconds: 20));
    expect(DeepSeekClient.defaultReceiveTimeout, const Duration(seconds: 20));
    expect(DeepSeekClient.defaultSendTimeout, const Duration(seconds: 20));

    final client = DeepSeekClient(apiKey: 'k');
    expect(client.connectTimeout, const Duration(seconds: 20));
    expect(client.receiveTimeout, const Duration(seconds: 20));
    expect(client.sendTimeout, const Duration(seconds: 20));
  });

  test('request disables thinking mode for fast responses', () async {
    final adapter = _CaptureAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final client = DeepSeekClient(apiKey: 'k', dio: dio);

    await client.generateWord(word: 'run', proficiency: Proficiency.cet);

    final body = adapter.requests.single;
    expect(body['model'], 'deepseek-v4-flash');
    // v4 系列 thinking 默认 enabled(思维链让响应长达数十秒,撞超时被误判挂起);
    // 显式禁用,恢复非思考模式的快速响应
    expect(body['thinking'], {'type': 'disabled'});
  });

  test('slow response times out and maps to transient error', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      await Future<void>.delayed(const Duration(seconds: 2));
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({
        'choices': [
          {
            'message': {
              'role': 'assistant',
              'content': '{}',
            },
          },
        ],
      }));
      await request.response.close();
    });

    final client = DeepSeekClient(
      apiKey: 'k',
      baseUrl: 'http://127.0.0.1:${server.port}',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(milliseconds: 100),
      sendTimeout: const Duration(seconds: 5),
    );
    await expectLater(
      client.generateWord(word: 'run', proficiency: Proficiency.cet),
      throwsA(isA<GenerationApiException>().having(
        (e) => e.kind,
        'kind',
        GenerationErrorKind.transient,
      )),
    );
  });
}
