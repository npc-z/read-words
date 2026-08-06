/// 生成任务控制台(§6 + 原型 #13 A+C 组合):全局队列(§6.1)的词集视图。
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:read_words/data/app_database.dart';
import 'package:read_words/data/repositories.dart';
import 'package:read_words/generation/generation_queue.dart';

/// 生成任务控制台:顶部大进度卡(分段进度 + 统计 + 状态徽章)+ 词表驱动列表。
class TaskConsolePage extends StatefulWidget {
  const TaskConsolePage({
    super.key,
    required this.wordSet,
    required this.repositories,
    required this.queue,
  });

  final WordSet wordSet;
  final Repositories repositories;

  /// 全局生成队列(§6.1 单队列双优先级)
  final GenerationQueue queue;

  @override
  State<TaskConsolePage> createState() => _TaskConsolePageState();
}

class _TaskConsolePageState extends State<TaskConsolePage> {
  List<Word> _words = [];
  bool _loading = true;
  bool _cancelled = false;

  @override
  void initState() {
    super.initState();
    widget.queue.addListener(_onQueueChanged);
    _init();
  }

  @override
  void dispose() {
    widget.queue.removeListener(_onQueueChanged);
    super.dispose();
  }

  Future<void> _init() async {
    // 批次入队(未生成词);已在队列的跳过
    unawaited(widget.queue.startBatch(widget.wordSet.id));
    await _reload();
  }

  void _onQueueChanged() {
    if (mounted) _reload();
  }

  Future<void> _reload() async {
    final ws = await widget.repositories.wordsInSet(widget.wordSet.id);
    if (mounted) {
      setState(() {
        _words = ws;
        _loading = false;
      });
    }
  }

  int get _successCount =>
      _words.where((w) => w.status == WordStatus.done.name).length;
  int get _failureCount =>
      _words.where((w) => w.status == WordStatus.failed.name).length;
  int get _pendingCount => _words
      .where(
        (w) =>
            w.status == WordStatus.queued.name ||
            w.status == WordStatus.generating.name,
      )
      .length;

  String _badge() {
    if (_cancelled) return '已取消';
    if (_pendingCount == 0) return '已完成'; // 本词集无待处理词
    if (widget.queue.paused) return '已暂停';
    if (widget.queue.running) return '生成中';
    if (widget.queue.budgetExhausted) return '已达今日预算';
    return '已完成';
  }

  Future<void> _cancel() async {
    await widget.queue.cancelWordSet(widget.wordSet.id);
    if (mounted) {
      setState(() => _cancelled = true);
    }
  }

  Future<void> _continueBackground() async {
    await widget.queue.continueBackground();
    if (widget.queue.budgetExhausted && mounted) {
      // 同日仍达限:给用户反馈而非静默无操作
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已达今日预算,次日重置后可继续')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final queue = widget.queue;
    return Scaffold(
      appBar: AppBar(
        title: const Text('生成任务'),
        actions: [
          if (!_loading && _pendingCount > 0) ...[
            if (queue.paused)
              TextButton(onPressed: queue.resume, child: const Text('继续')),
            if (queue.running && !queue.paused)
              TextButton(onPressed: queue.pause, child: const Text('暂停')),
            TextButton(onPressed: _cancel, child: const Text('取消')),
          ],
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _ProgressCard(
                  queue: queue,
                  words: _words,
                  badge: _badge(),
                  successCount: _successCount,
                  failureCount: _failureCount,
                  pendingCount: _pendingCount,
                  onContinue: _continueBackground,
                ),
                Expanded(
                  child: _TaskList(words: _words, queue: queue),
                ),
              ],
            ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.queue,
    required this.words,
    required this.badge,
    required this.successCount,
    required this.failureCount,
    required this.pendingCount,
    required this.onContinue,
  });

  final GenerationQueue queue;
  final List<Word> words;
  final String badge;
  final int successCount;
  final int failureCount;
  final int pendingCount;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Chip(label: Text(badge), visualDensity: VisualDensity.compact),
                const Spacer(),
                Text(
                  '成功 $successCount · 失败 $failureCount · 剩余 $pendingCount',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _BudgetStrip(queue: queue, onContinue: onContinue),
            const SizedBox(height: 12),
            _SegmentedBar(words: words),
          ],
        ),
      ),
    );
  }
}

/// 预算提示条(§6.2):今日预算 used/limit;达限显示"继续下一批次"。
class _BudgetStrip extends StatelessWidget {
  const _BudgetStrip({required this.queue, required this.onContinue});

  final GenerationQueue queue;

  /// 点击"继续下一批次";同日仍达限时由页面给出提示
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final state = queue.budgetState;
    if (state == null) return const SizedBox.shrink();
    final ratio = (state.used / state.limit).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '今日预算 ${state.used}/${state.limit}',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: ratio, minHeight: 6),
        ),
        if (queue.budgetExhausted) ...[
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: onContinue,
            child: const Text('继续下一批次'),
          ),
        ],
      ],
    );
  }
}

class _SegmentedBar extends StatelessWidget {
  const _SegmentedBar({required this.words});

  final List<Word> words;

  @override
  Widget build(BuildContext context) {
    if (words.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: const SizedBox(
          height: 10,
          child: ColoredBox(color: Color(0xFFE0E0E0)),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 10,
        child: Row(
          children: [
            for (final w in words)
              Expanded(child: ColoredBox(color: statusColor(w.status))),
          ],
        ),
      ),
    );
  }
}

Color statusColor(String status) => switch (status) {
  'done' => const Color(0xFF34C759),
  'failed' => const Color(0xFFFF3B30),
  'generating' => const Color(0xFF2563EB),
  'queued' => const Color(0xFFFFCC00),
  _ => const Color(0xFFE0E0E0),
};

WordStatus statusOf(String status) => WordStatus.values.firstWhere(
  (s) => s.name == status,
  orElse: () => WordStatus.notGenerated,
);

class _TaskList extends StatelessWidget {
  const _TaskList({required this.words, required this.queue});

  final List<Word> words;
  final GenerationQueue queue;

  @override
  Widget build(BuildContext context) {
    if (words.isEmpty) {
      return const Center(child: Text('没有待生成的词'));
    }
    return ListView.builder(
      itemCount: words.length,
      itemBuilder: (context, i) {
        final w = words[i];
        final status = statusOf(w.status);
        return ListTile(
          leading: _StatusIcon(status: status),
          title: Text(w.headword),
          subtitle: status == WordStatus.failed
              ? Text(
                  queue.errors[w.id] ?? '生成失败',
                  style: const TextStyle(color: Colors.red),
                )
              : Text(status.label, style: const TextStyle(fontSize: 12)),
          trailing: status == WordStatus.failed
              ? IconButton(
                  tooltip: '重试',
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    if (queue.budgetExhausted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('已达今日预算,次日重置后可重试')),
                      );
                      return;
                    }
                    queue.retry(w.id);
                  },
                )
              : null,
        );
      },
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status});

  final WordStatus status;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      WordStatus.done => Icon(
        Icons.check_circle,
        color: statusColor(status.name),
      ),
      WordStatus.failed => Icon(Icons.error, color: statusColor(status.name)),
      WordStatus.generating => const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      WordStatus.queued => Icon(
        Icons.schedule,
        color: statusColor(status.name),
      ),
      WordStatus.notGenerated => Icon(
        Icons.circle_outlined,
        color: statusColor(status.name),
      ),
    };
  }
}
