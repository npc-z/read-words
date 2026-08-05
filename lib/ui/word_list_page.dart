import 'package:flutter/material.dart';
import 'package:read_words/data/app_database.dart';
import 'package:read_words/data/repositories.dart';
import 'package:read_words/ui/word_detail_page.dart';

/// 词集内单词列表
class WordListPage extends StatefulWidget {
  const WordListPage({
    super.key,
    required this.wordSet,
    required this.repositories,
  });

  final WordSet wordSet;
  final Repositories repositories;

  @override
  State<WordListPage> createState() => _WordListPageState();
}

class _WordListPageState extends State<WordListPage> {
  late Future<List<Word>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repositories.wordsInSet(widget.wordSet.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.wordSet.name)),
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
                  WordStatus.values
                      .firstWhere((s) => s.name == w.status)
                      .label,
                  style: const TextStyle(fontSize: 12),
                ),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WordDetailPage(
                        word: w,
                        repositories: widget.repositories,
                      ),
                    ),
                  );
                  setState(() {
                    _future = widget.repositories.wordsInSet(widget.wordSet.id);
                  });
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
