/// 生成任务控制(§6:批次、状态流转、单点重试、取消、预算门槛)。
library;

import 'package:flutter/foundation.dart';
import 'package:read_words/data/app_database.dart';
import 'package:read_words/data/repositories.dart';
import 'package:read_words/generation/budget.dart';
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

/// 批次控制器:装载词集未生成词,顺序生成,支持单点重试、取消与预算门槛(§6.2)。
class GenerationTaskController extends ChangeNotifier {
  GenerationTaskController({
    required this.wordSetId,
    required this.repositories,
    required this.service,
    BudgetLedger? budget,
  }) : budget = budget ?? BudgetLedger(repositories: repositories);

  final int wordSetId;
  final Repositories repositories;
  final GenerationService service;

  /// 预算账本:只约束本批次(后台预生成);即时生成不经由此控制器
  final BudgetLedger budget;

  final List<GenerationTask> tasks = [];
  final List<int> _queue = [];

  bool _started = false;
  bool _running = false;
  bool _cancelled = false;
  bool _budgetExhausted = false;

  bool get running => _running;
  bool get cancelled => _cancelled;

  /// 已达今日预算(后台预生成上限 M×X,§6.2)
  bool get budgetExhausted => _budgetExhausted;

  /// 最近一次预算快照(UI 展示);随批次推进刷新
  BudgetState? budgetState;

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
  /// 预算暂停中取消:排队词直接回未生成。
  Future<void> cancel() async {
    if (_cancelled) return;
    if (!_running && !_budgetExhausted) return;
    _cancelled = true;
    notifyListeners();
    if (!_running) {
      await _resetQueue();
      _budgetExhausted = false;
      notifyListeners();
    }
  }

  /// 继续下一批次:预算达限暂停后,次日自然日重置时恢复剩余排队词(§6.2)。
  Future<void> continueBatch() async {
    if (_running || !_budgetExhausted) return;
    await _run();
  }

  /// 单点重试:失败词重新入队(队头),批次空闲时立即重跑该词。
  /// 已达今日预算时不重试(§6.2 预算只约束后台预生成)。
  Future<void> retry(int wordId) async {
    final task = _taskFor(wordId);
    if (task == null || task.status != WordStatus.failed) return;
    if (await budget.exhausted()) return;
    if (task.status != WordStatus.failed) return; // 双检:await 窗口内已重试
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

  Future<void> _refreshBudget() async {
    budgetState = await budget.state();
  }

  Future<void> _run() async {
    _running = true;
    _cancelled = false;
    _budgetExhausted = false; // 本轮运行中重新判定
    notifyListeners();
    try {
      while (_queue.isNotEmpty && !_cancelled) {
        // 预算门槛(§6.2):达限暂停,剩余排队词保留
        await _refreshBudget();
        if (budgetState!.exhausted) {
          _budgetExhausted = true;
          notifyListeners();
          break;
        }
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
        if (!outcome.failed) {
          await budget.record(1); // 成功生成一词才计入当日预算
        }
        notifyListeners();
      }
      if (_cancelled) {
        await _resetQueue();
      }
    } finally {
      _running = false;
      if (!_cancelled) await _refreshBudget(); // 末词后的用量同步给 UI
      notifyListeners();
    }
  }

  /// 取消时:剩余排队词回未生成
  Future<void> _resetQueue() async {
    for (final id in _queue) {
      final task = _taskFor(id)!;
      task.status = WordStatus.notGenerated;
      task.error = null;
      await repositories.setWordStatus(id, WordStatus.notGenerated);
    }
    _queue.clear();
  }
}
