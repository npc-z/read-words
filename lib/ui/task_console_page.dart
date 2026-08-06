/// 生成任务控制台(§6 + 原型 #13 A+C 组合;并发池见 #17)。
library;

import 'package:flutter/material.dart';
import 'package:read_words/data/app_database.dart';
import 'package:read_words/data/repositories.dart';
import 'package:read_words/generation/generation_service.dart';
import 'package:read_words/generation/task_controller.dart';

/// 生成任务控制台:顶部大进度卡(分段进度 + 统计 + 状态徽章)+ 词表驱动列表。
class TaskConsolePage extends StatefulWidget {
  const TaskConsolePage({
    super.key,
    required this.wordSet,
    required this.repositories,
    this.service,
  });

  final WordSet wordSet;
  final Repositories repositories;

  /// 注入用;为空时按设置构造默认服务
  final GenerationService? service;

  @override
  State<TaskConsolePage> createState() => _TaskConsolePageState();
}

class _TaskConsolePageState extends State<TaskConsolePage> {
  GenerationTaskController? _controller;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final service =
        widget.service ?? await buildGenerationService(widget.repositories);
    if (!mounted) return;
    final controller = GenerationTaskController(
      wordSetId: widget.wordSet.id,
      repositories: widget.repositories,
      service: service,
    );
    controller.addListener(_onChanged);
    setState(() => _controller = controller);
    await controller.start();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.removeListener(_onChanged);
    _controller?.dispose();
    super.dispose();
  }

  String _badge(GenerationTaskController c) {
    if (c.running) return '生成中';
    if (c.cancelled) return '已取消';
    return '已完成';
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      appBar: AppBar(
        title: const Text('生成任务'),
        actions: [
          if (controller != null && controller.running)
            TextButton(
              onPressed: controller.cancel,
              child: const Text('取消'),
            ),
        ],
      ),
      body: controller == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _ProgressCard(controller: controller, badge: _badge(controller)),
                Expanded(child: _TaskList(controller: controller)),
              ],
            ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.controller, required this.badge});

  final GenerationTaskController controller;
  final String badge;

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
                Chip(
                  label: Text(badge),
                  visualDensity: VisualDensity.compact,
                ),
                const Spacer(),
                Text(
                  '成功 ${controller.successCount} · 失败 ${controller.failureCount}'
                  ' · 剩余 ${controller.pendingCount}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SegmentedBar(controller: controller),
          ],
        ),
      ),
    );
  }
}

class _SegmentedBar extends StatelessWidget {
  const _SegmentedBar({required this.controller});

  final GenerationTaskController controller;

  @override
  Widget build(BuildContext context) {
    final tasks = controller.tasks;
    if (tasks.isEmpty) {
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
            for (final t in tasks)
              Expanded(
                child: ColoredBox(color: statusColor(t.status)),
              ),
          ],
        ),
      ),
    );
  }
}

Color statusColor(WordStatus status) => switch (status) {
      WordStatus.done => const Color(0xFF34C759),
      WordStatus.failed => const Color(0xFFFF3B30),
      WordStatus.generating => const Color(0xFF2563EB),
      WordStatus.queued => const Color(0xFFFFCC00),
      WordStatus.notGenerated => const Color(0xFFE0E0E0),
    };

class _TaskList extends StatelessWidget {
  const _TaskList({required this.controller});

  final GenerationTaskController controller;

  @override
  Widget build(BuildContext context) {
    final tasks = controller.tasks;
    if (tasks.isEmpty) {
      return const Center(child: Text('没有待生成的词'));
    }
    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, i) {
        final t = tasks[i];
        return ListTile(
          leading: _StatusIcon(status: t.status),
          title: Text(t.headword),
          subtitle: t.status == WordStatus.failed
              ? Text(t.error ?? '生成失败', style: const TextStyle(color: Colors.red))
              : Text(t.status.label, style: const TextStyle(fontSize: 12)),
          trailing: t.status == WordStatus.failed
              ? IconButton(
                  tooltip: '重试',
                  icon: const Icon(Icons.refresh),
                  onPressed: () => controller.retry(t.wordId),
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
      WordStatus.done =>
        Icon(Icons.check_circle, color: statusColor(status)),
      WordStatus.failed => Icon(Icons.error, color: statusColor(status)),
      WordStatus.generating =>
        const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
      WordStatus.queued =>
        Icon(Icons.schedule, color: statusColor(status)),
      WordStatus.notGenerated =>
        Icon(Icons.circle_outlined, color: statusColor(status)),
    };
  }
}
