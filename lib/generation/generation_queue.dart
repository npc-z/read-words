/// 生成队列(§6.1 单队列双优先级):任务持久化,即时生成最高优先,
/// 后台预生成受预算约束;重启续跑。
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:read_words/data/app_database.dart';
import 'package:read_words/data/repositories.dart';
import 'package:read_words/generation/budget.dart';
import 'package:read_words/generation/generation_service.dart';

/// 全局生成队列:唯一的生成消费端(worker 池)。
///
/// - 任务持久化于 generation_tasks 表(行存在即待处理,结算后删除);
/// - 优先级:1=即时生成(点开未生成词)最高,0=后台预生成;
/// - 预算只约束后台任务;即时生成不受限;
/// - 重启/切后台后由 [resumePending] 续跑。
class GenerationQueue extends ChangeNotifier {
  GenerationQueue({
    required this.repositories,
    required this.service,
    BudgetLedger? budget,
  }) : budget = budget ?? BudgetLedger(repositories: repositories);

  final Repositories repositories;
  final GenerationService service;

  /// 预算账本:只约束后台预生成任务
  final BudgetLedger budget;

  /// 失败原因缓存(内存):wordId → 错误信息;重试成功后清除
  final Map<int, String> errors = {};

  bool _running = false;
  bool _paused = false;
  bool _budgetExhausted = false;

  /// 运行期间有新任务入队;本轮结束后需再消费一轮
  bool _dispatchQueued = false;

  bool get running => _running;

  /// 已暂停:不再消费新任务(§6)
  bool get paused => _paused;

  /// 已达今日预算(后台预生成上限 M×X,§6.2)
  bool get budgetExhausted => _budgetExhausted;

  /// 最近一次预算快照(UI 展示);随批次推进刷新
  BudgetState? budgetState;

  /// 待处理任务数(全词集)
  Future<int> get pendingCount => repositories.pendingGenerationTaskCount();

  /// 词集后台批次入队:全部未生成词(§6.1);已待处理的跳过。
  Future<void> startBatch(int wordSetId) async {
    final ws = await repositories.wordsInSet(wordSetId);
    for (final w in ws) {
      if (w.status != WordStatus.notGenerated.name) continue;
      await repositories.insertGenerationTask(w.id, priority: 0);
      await repositories.setWordStatus(w.id, WordStatus.queued);
    }
    _dispatchQueued = true; // 运行中的话,当前轮结束后续跑
    notifyListeners();
    unawaited(_ensureRunning());
  }

  /// 即时生成入队(§6.1 最高优先);词不存在或已完成则忽略。
  Future<void> enqueue(int wordId, {bool immediate = false}) async {
    final word = await repositories.wordById(wordId);
    if (word == null || word.status == WordStatus.done.name) return;
    final wasPending = word.status == WordStatus.queued.name ||
        word.status == WordStatus.generating.name;
    await repositories.insertGenerationTask(
      wordId,
      priority: immediate ? 1 : 0,
    );
    if (!wasPending) {
      // 在飞词保持 generating,不打回 queued
      await repositories.setWordStatus(wordId, WordStatus.queued);
    }
    _dispatchQueued = true;
    notifyListeners();
    unawaited(_ensureRunning());
  }

  /// 单点重试:失败词重新入队(后台优先级);已达今日预算时不重试。
  Future<void> retry(int wordId) async {
    final word = await repositories.wordById(wordId);
    if (word == null || word.status != WordStatus.failed.name) return;
    if (await budget.exhausted()) return;
    await enqueue(wordId);
  }

  /// 重启/切后台续跑:中断(generating)任务复位后继续消费(§6.1)。
  Future<void> resumePending() async {
    await repositories.resetInterruptedTasks();
    notifyListeners();
    await _ensureRunning();
  }

  /// 暂停:在飞任务结算,不再消费新任务(§6)。
  Future<void> pause() async {
    if (!_running || _paused) return;
    _paused = true;
    notifyListeners();
  }

  /// 继续:恢复消费(§6)。
  Future<void> resume() async {
    if (!_paused) return;
    _paused = false;
    _dispatchQueued = true;
    notifyListeners();
    await _ensureRunning();
  }

  /// 继续后台批次:预算达限暂停后,次日自然日重置时恢复(§6.2)。
  Future<void> continueBackground() async {
    if (_running || _paused || !_budgetExhausted) return;
    await _ensureRunning();
  }

  /// 撤销词集的后台批次:排队任务回未生成(§6.1);在飞任务正常结算。
  Future<void> cancelWordSet(int wordSetId) async {
    final pending = await repositories.backgroundPendingWordIds(wordSetId);
    for (final wordId in pending) {
      await repositories.deleteGenerationTaskByWord(wordId);
      await repositories.setWordStatus(wordId, WordStatus.notGenerated);
      errors.remove(wordId);
    }
    notifyListeners();
  }

  Future<void> _refreshBudget() async {
    budgetState = await budget.state();
  }

  /// 当前运行中的消费循环;单飞保证不并发(§6.1)
  Future<void>? _inflight;

  /// 启动/复用消费循环:已有运行则等待其消化(do-while 会覆盖新入队任务)
  Future<void> _ensureRunning() async {
    if (_paused) return;
    final active = _inflight;
    if (active != null) return active;
    final run = _run();
    _inflight = run;
    try {
      await run;
    } finally {
      _inflight = null;
    }
    // 丢失唤醒补偿:运行结束后仍有任务(运行收尾窗口内入队)且未被暂停/达限,续跑
    if (!_paused &&
        !_budgetExhausted &&
        await repositories.pendingGenerationTaskCount() > 0) {
      await _ensureRunning();
    }
  }

  /// 消费循环:并发数从设置读取(§6.5,默认 4),上限保护 16。
  /// 运行期间有新任务入队则多消费一轮。
  Future<void> _run() async {
    do {
      _dispatchQueued = false;
      _running = true;
      _paused = false;
      _budgetExhausted = false; // 本轮运行中重新判定
      notifyListeners();
      try {
        final settings = await repositories.settings();
        final workers = settings.concurrency.clamp(1, 16);
        await Future.wait([for (var i = 0; i < workers; i++) _worker()]);
        // 达限标志收尾重算:仍有任务 且 预算达限才为真
        _budgetExhausted = false;
        if (await repositories.pendingGenerationTaskCount() > 0) {
          _budgetExhausted = await budget.exhausted();
        }
      } finally {
        _running = false;
        await _refreshBudget();
        notifyListeners();
      }
    } while (_dispatchQueued && !_paused);
  }

  /// 单个 worker:原子领取(优先级高先)→ 生成 → 结算;暂停/达限/无任务即退出。
  Future<void> _worker() async {
    while (!_paused) {
      final task = await repositories.claimNextGenerationTask();
      if (task == null) return; // 队列空
      final isImmediate = task.priority == 1;
      var reserved = false;
      if (!isImmediate) {
        // 预算门槛(§6.2):只约束后台任务;达限即退出,任务归还
        if (!await budget.reserve()) {
          await repositories.unclaimGenerationTask(task.id);
          _budgetExhausted = true;
          notifyListeners();
          return;
        }
        reserved = true;
      }
      try {
        final word = await repositories.wordById(task.wordId);
        if (word == null ||
            word.status == WordStatus.done.name ||
            word.status == WordStatus.notGenerated.name) {
          // 词已删除/已完成(崩溃窗口)/被取消:任务作废
          await repositories.deleteGenerationTask(task.id);
          if (reserved) await budget.release();
          continue;
        }
        final outcome = await service.generateWord(task.wordId);
        if (outcome.failed) {
          errors[task.wordId] = outcome.error ?? '生成失败';
          if (reserved) {
            await budget.release(); // 失败不耗预算
            reserved = false;
          }
        } else {
          errors.remove(task.wordId);
        }
        await repositories.deleteGenerationTask(task.id);
        await _refreshBudget();
        notifyListeners();
      } catch (e) {
        // 结算异常(如 DB 忙):按失败落定,任务出队,不打断整轮消费
        if (reserved) await budget.release();
        errors[task.wordId] = '$e';
        await repositories.deleteGenerationTask(task.id);
        await repositories.setWordStatus(task.wordId, WordStatus.failed);
        await _refreshBudget();
        notifyListeners();
      }
    }
  }
}
