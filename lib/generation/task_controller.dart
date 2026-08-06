/// 生成任务控制(§6:批次、状态流转、单点重试、取消)。
library;

import 'package:flutter/foundation.dart';
import 'package:read_words/data/app_database.dart';
import 'package:read_words/data/repositories.dart';
import 'package:read_words/generation/generation_service.dart';

/// 批次中的一个生成任务(词)
class GenerationTask {
  GenerationTask({
    required this.wordId,
    required this.headword,
    required this.status,
  });

  final int wordId;
  final String headword;

  /// 当前状态(queued → generating → done/failed;取消后未处理词回 notGenerated)
  WordStatus status;
  String? error;
}

/// 批次控制器:装载词集未生成词,顺序生成,支持单点重试与取消。
class GenerationTaskController extends ChangeNotifier {
  GenerationTaskController({
    required this.wordSetId,
    required this.repositories,
    required this.service,
  });

  final int wordSetId;
  final Repositories repositories;
  final GenerationService service;

  final List<GenerationTask> tasks = [];
  final List<int> _queue = [];

  bool _started = false;
  bool _running = false;
  bool _cancelled = false;

  bool get running => _running;
  bool get cancelled => _cancelled;

  int get successCount =>
      tasks.where((t) => t.status == WordStatus.done).length;
  int get failureCount =>
      tasks.where((t) => t.status == WordStatus.failed).length;
  int get pendingCount => tasks.where((t) =>
      t.status == WordStatus.queued || t.status == WordStatus.generating).length;

  /// 批次 = 词集全部未生成词;仅可启动一次。
  Future<void> start() async {
    if (_started) return;
    _started = true;
    final words = await repositories.wordsInSet(wordSetId);
    for (final w in words) {
      if (w.status != WordStatus.notGenerated.name) continue;
      tasks.add(GenerationTask(
        wordId: w.id,
        headword: w.headword,
        status: WordStatus.queued,
      ));
      _queue.add(w.id);
      await repositories.setWordStatus(w.id, WordStatus.queued);
    }
    if (tasks.isEmpty) {
      notifyListeners();
      return;
    }
    await _run();
  }

  /// 请求取消:当前词完成后停止,剩余排队词回未生成(已生成部分保留)。
  Future<void> cancel() async {
    if (!_running || _cancelled) return;
    _cancelled = true;
    notifyListeners();
  }

  /// 单点重试:失败词重新入队(队头),批次空闲时立即重跑该词。
  Future<void> retry(int wordId) async {
    final task = _taskFor(wordId);
    if (task == null || task.status != WordStatus.failed) return;
    task.status = WordStatus.queued;
    task.error = null;
    await repositories.setWordStatus(wordId, WordStatus.queued);
    _queue.insert(0, wordId);
    notifyListeners();
    if (_running) return;
    await _run();
  }

  GenerationTask? _taskFor(int wordId) {
    for (final t in tasks) {
      if (t.wordId == wordId) return t;
    }
    return null;
  }

  Future<void> _run() async {
    _running = true;
    _cancelled = false;
    notifyListeners();
    while (_queue.isNotEmpty && !_cancelled) {
      final id = _queue.removeAt(0);
      final task = _taskFor(id)!;
      task.status = WordStatus.generating;
      notifyListeners();
      final outcome = await service.generateWord(id);
      if (_cancelled && outcome.failed) {
        // 取消请求后才落定的失败 = 未完成,回未生成
        task.status = WordStatus.notGenerated;
        task.error = null;
        await repositories.setWordStatus(id, WordStatus.notGenerated);
        continue;
      }
      task.status = outcome.failed ? WordStatus.failed : WordStatus.done;
      task.error = outcome.error;
      notifyListeners();
    }
    if (_cancelled) {
      for (final id in _queue) {
        final task = _taskFor(id)!;
        task.status = WordStatus.notGenerated;
        task.error = null;
        await repositories.setWordStatus(id, WordStatus.notGenerated);
      }
      _queue.clear();
    }
    _running = false;
    notifyListeners();
  }
}
