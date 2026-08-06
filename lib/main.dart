import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:read_words/data/db.dart';
import 'package:read_words/data/repositories.dart';
import 'package:read_words/generation/generation_queue.dart';
import 'package:read_words/generation/generation_service.dart';
import 'package:read_words/ui/word_set_list_page.dart';
import 'package:workmanager/workmanager.dart';

/// workmanager 后台任务:续跑未完成生成批次(§6.1;Web 端不走此路径)。
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final db = await openDatabase();
      final repositories = Repositories(db);
      final queue = GenerationQueue(
        repositories: repositories,
        service: await buildGenerationService(repositories),
      );
      await queue.resumePending(); // 后台跑到空闲或达预算
      await db.close();
    } catch (_) {
      // 后台任务失败不重抛,避免系统标记崩溃
    }
    return true;
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Android 后台调度(workmanager);Web 降级为前台续跑
  if (!kIsWeb) {
    await Workmanager().initialize(callbackDispatcher);
    await Workmanager().registerPeriodicTask(
      'generation-resume',
      'resumeGeneration',
      frequency: const Duration(minutes: 15),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  }

  final db = await openDatabase();
  final repositories = Repositories(db);
  final queue = GenerationQueue(
    repositories: repositories,
    service: await buildGenerationService(repositories),
  );
  // 前台续跑不阻塞首帧:队列在后台消化,页面经监听器刷新
  unawaited(queue.resumePending());

  runApp(ReadWordsApp(repositories: repositories, queue: queue));
}

class ReadWordsApp extends StatelessWidget {
  const ReadWordsApp({
    super.key,
    required this.repositories,
    required this.queue,
  });

  final Repositories repositories;
  final GenerationQueue queue;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '阅读学单词',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        useMaterial3: true,
      ),
      home: WordSetListPage(repositories: repositories, queue: queue),
    );
  }
}
