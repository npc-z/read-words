import 'package:flutter/material.dart';
import 'package:read_words/data/app_database.dart';
import 'package:read_words/data/repositories.dart';
import 'package:read_words/generation/generation_queue.dart';
import 'package:read_words/ui/review_queue_page.dart';
import 'package:read_words/ui/task_console_page.dart';
import 'package:read_words/ui/word_detail_page.dart';

/// 词集内单词列表
class WordListPage extends StatefulWidget {
  const WordListPage({
    super.key,
    required this.wordSet,
    required this.repositories,
    required this.queue,
  });

  final WordSet wordSet;
  final Repositories repositories;
  final GenerationQueue queue;

  @override
  State<WordListPage> createState() => _WordListPageState();
}

class _WordListPageState extends State<WordListPage> {
  late Future<List<Word>> _future;
  late Future<int> _dueCount;

  @override
  void initState() {
    super.initState();
    _future = widget.repositories.wordsInSet(widget.wordSet.id);
    _dueCount = widget.repositories.dueReviewCount(widget.wordSet.id);
  }

  void _refresh() {
    setState(() {
      _future = widget.repositories.wordsInSet(widget.wordSet.id);
      _dueCount = widget.repositories.dueReviewCount(widget.wordSet.id);
    });
  }

  Future<void> _openReview() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewQueuePage(
          wordSet: widget.wordSet,
          repositories: widget.repositories,
          queue: widget.queue,
        ),
      ),
    );
    if (!mounted) return;
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.wordSet.name),
        actions: [
          FutureBuilder<int>(
            future: _dueCount,
            builder: (context, snapshot) {
              final n = snapshot.data ?? 0;
              return IconButton(
                tooltip: '复习',
                icon: Badge(
                  isLabelVisible: n > 0,
                  label: Text('$n'),
                  child: const Icon(Icons.replay),
                ),
                onPressed: _openReview,
              );
            },
          ),
          IconButton(
            tooltip: '开始生成',
            icon: const Icon(Icons.auto_awesome),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TaskConsolePage(
                    wordSet: widget.wordSet,
                    repositories: widget.repositories,
                    queue: widget.queue,
                  ),
                ),
              );
              if (!mounted) return;
              _refresh();
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Word>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final words = snapshot.data ?? const [];
          if (words.isEmpty) {
            return const Center(child: Text('还没有单词,点击右上角导入'));
          }
          return ListView.builder(
            itemCount: words.length,
            itemBuilder: (context, i) {
              final w = words[i];
              return ListTile(
                title: Text(w.headword),
                subtitle: Text(
                  WordStatus.values.firstWhere((s) => s.name == w.status).label,
                  style: const TextStyle(fontSize: 12),
                ),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WordDetailPage(
                        word: w,
                        repositories: widget.repositories,
                        queue: widget.queue,
                      ),
                    ),
                  );
                  if (mounted) _refresh();
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final words = await widget.repositories.wordsInSet(widget.wordSet.id);
          if (words.isEmpty || !context.mounted) return;
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WordDetailPage(
                word: words.first,
                repositories: widget.repositories,
                queue: widget.queue,
              ),
            ),
          );
        },
        icon: const Icon(Icons.menu_book),
        label: const Text('开始学习'),
      ),
    );
  }
}
