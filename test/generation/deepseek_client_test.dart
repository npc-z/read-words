import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:read_words/generation/deepseek_client.dart';
import 'package:read_words/generation/prompt.dart';

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
