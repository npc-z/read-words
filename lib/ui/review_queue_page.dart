import 'package:flutter/material.dart';
import 'package:read_words/data/app_database.dart';
import 'package:read_words/data/repositories.dart';
import 'package:read_words/data/settings.dart';
import 'package:read_words/generation/generation_queue.dart';
import 'package:read_words/ui/word_detail_page.dart';

/// 到期复习列表(§8.4):nextReviewAt 到期(含逾期)的词,按到期时间升序。
/// 打开词进入复习模式(逐句精读器),返回后点「完成复习」按 1/3/7 推进。
class ReviewQueuePage extends StatefulWidget {
  const ReviewQueuePage({
    super.key,
    required this.wordSet,
    required this.repositories,
    required this.queue,
  });

  final WordSet wordSet;
  final Repositories repositories;
  final GenerationQueue queue;

  @override
  State<ReviewQueuePage> createState() => _ReviewQueuePageState();
}

class _ReviewQueuePageState extends State<ReviewQueuePage> {
  late Future<List<DueReviewWord>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repositories.dueReviewWords(widget.wordSet.id);
  }

  void _refresh() {
    setState(() {
      _future = widget.repositories.dueReviewWords(widget.wordSet.id);
    });
  }

  Future<void> _complete(DueReviewWord word) async {
    final next = await widget.repositories.advanceReview(word.wordId);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('已复习,$next 天后再来')));
    _refresh();
  }

  Future<void> _openWord(DueReviewWord word) async {
    final w = await widget.repositories.wordById(word.wordId);
    if (w == null || !mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WordDetailPage(
          word: w,
          repositories: widget.repositories,
          queue: widget.queue,
          initialMode: ViewMode.review,
        ),
      ),
    );
    if (!mounted) return;
    _refresh();
  }

  String _dueLabel(DateTime at) {
    final now = DateTime.now();
    final local = at.toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final days = today
        .difference(DateTime(local.year, local.month, local.day))
        .inDays;
    return days <= 0 ? '今天到期' : '已逾期 $days 天';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('复习')),
      body: FutureBuilder<List<DueReviewWord>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  const Text('复习列表加载失败', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: _refresh, child: const Text('重试')),
                ],
              ),
            );
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final due = snapshot.data ?? const [];
          if (due.isEmpty) {
            return const Center(child: Text('今天没有到期词'));
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: due.length,
            itemBuilder: (context, i) {
              final word = due[i];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ListTile(
                  title: Text(word.headword),
                  subtitle: Text(
                    _dueLabel(word.nextReviewAt),
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: IconButton(
                    tooltip: '完成复习',
                    icon: const Icon(Icons.check_circle_outline),
                    onPressed: () => _complete(word),
                  ),
                  onTap: () => _openWord(word),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
