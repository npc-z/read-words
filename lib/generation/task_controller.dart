/// 生成任务控制(§6:批次、并发消费、状态流转、单点重试、取消、暂停/继续、预算)。
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

/// 批次控制器:装载词集未生成词,并发消费(§6.5),支持单点重试、取消、
/// 暂停/继续(§6)与预算门槛(§6.2)。
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
  bool _paused = false;
  bool _budgetExhausted = false;

  /// 运行期间有新词入队(重试等);本轮结束后需要再消费一轮
  bool _dispatchQueued = false;

  bool get running => _running;
  bool get cancelled => _cancelled;

  /// 已暂停:不再消费新词,排队词保持 queued(§6)
  bool get paused => _paused;

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

  /// 请求取消:当前在飞词结算后停止,剩余排队词回未生成(已生成部分保留)。
  /// 预算暂停/手动暂停中取消:排队词直接回未生成。
  Future<void> cancel() async {
    if (_cancelled) return;
    if (!_running && !_budgetExhausted && !_paused) return;
    _cancelled = true;
    _paused = false;
    notifyListeners();
    if (!_running) {
      await _resetQueue();
      _budgetExhausted = false;
      notifyListeners();
    }
  }

  /// 暂停:在飞词结算,不再消费新词(排队词保持 queued)(§6)。
  Future<void> pause() async {
    if (!_running || _paused || _cancelled) return;
    _paused = true;
    notifyListeners();
  }

  /// 继续:恢复消费排队词(§6)。
  Future<void> resume() async {
    if (!_paused || _cancelled) return;
    _paused = false;
    _dispatchQueued = true;
    notifyListeners();
    if (_running) return; // 在飞词结算中:当前运行会继续消费
    await _run();
  }

  /// 继续下一批次:预算达限暂停后,次日自然日重置时恢复剩余排队词(§6.2)。
  Future<void> continueBatch() async {
    if (_running || _paused || !_budgetExhausted) return;
    await _run();
  }

  /// 单点重试:失败词重新入队(队头),批次空闲时立即重跑该词。
  /// 已达今日预算时不重试(§6.2 预算只约束后台预生成)。
  Future<void> retry(int wordId) async {
    final task = _taskFor(wordId);
    if (task == null || _cancelled || task.status != WordStatus.failed) return;
    if (await budget.exhausted()) return;
    if (task.status != WordStatus.failed) return; // 双检:await 窗口内已重试
    task.status = WordStatus.queued;
    task.error = null;
    await repositories.setWordStatus(wordId, WordStatus.queued);
    _queue.insert(0, wordId);
    _dispatchQueued = true; // 运行中的话,当前轮结束后续跑
    notifyListeners();
    if (_running || _paused) return; // 运行/暂停中:由批次或继续消费
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

  /// 批次消费:并发数从设置读取(§6.5,默认 4),上限保护 16。
  /// 运行期间有新词入队(重试/继续)则多消费一轮。
  Future<void> _run() async {
    do {
      _dispatchQueued = false;
      _running = true;
      _cancelled = false;
      _paused = false;
      _budgetExhausted = false; // 本轮运行中重新判定
      notifyListeners();
      try {
        final settings = await repositories.settings();
        final workers = settings.concurrency.clamp(1, 16);
        await Future.wait([for (var i = 0; i < workers; i++) _worker()]);
        if (_cancelled) {
          await _resetQueue();
        }
        // 达限标志收尾重算:预算仍达限 且 队列仍有词才为真
        _budgetExhausted = false;
        if (!_cancelled && _queue.isNotEmpty) {
          _budgetExhausted = await budget.exhausted();
        }
      } finally {
        _running = false;
        if (!_cancelled) await _refreshBudget();
        notifyListeners();
      }
    } while (_dispatchQueued && !_cancelled && !_paused);
  }

  /// 单个 worker:预约预算 → 取词 → 生成 → 结算;暂停/取消/达限即退出。
  Future<void> _worker() async {
    while (!_cancelled && !_paused) {
      // 预算门槛(§6.2):达限即退出,剩余排队词保留(标志由 _run 收尾重算)
      if (!await budget.reserve()) {
        return;
      }
      var reserved = true;
      try {
        if (_cancelled || _paused) {
          await budget.release();
          return;
        }
        final id = _takeNext();
        if (id == null) {
          await budget.release(); // 队列已空,归还预约
          return;
        }
        final task = _taskFor(id)!;
        task.status = WordStatus.generating;
        notifyListeners();
        final outcome = await service.generateWord(id);
        if (_cancelled && outcome.failed) {
          // 取消请求后才落定的失败 = 未完成,回未生成
          task.status = WordStatus.notGenerated;
          task.error = null;
          await repositories.setWordStatus(id, WordStatus.notGenerated);
          await budget.release();
          continue;
        }
        task.status = outcome.failed ? WordStatus.failed : WordStatus.done;
        task.error = outcome.error;
        if (outcome.failed) {
          await budget.release(); // 失败不耗预算
          reserved = false;
        }
        await _refreshBudget();
        notifyListeners();
      } catch (_) {
        // 结算异常:归还预约,避免预算泄漏
        if (reserved) await budget.release();
        rethrow;
      }
    }
  }

  int? _takeNext() {
    if (_queue.isEmpty) return null;
    return _queue.removeAt(0);
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
