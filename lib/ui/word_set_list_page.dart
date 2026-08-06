import 'package:flutter/material.dart';
import 'package:read_words/data/app_database.dart';
import 'package:read_words/data/repositories.dart';
import 'package:read_words/import/import_service.dart';
import 'package:read_words/ui/word_list_page.dart';

/// 词集列表页(§7.3:词集即中心,创建 → 导入单词表)
class WordSetListPage extends StatefulWidget {
  const WordSetListPage({super.key, required this.repositories});

  final Repositories repositories;

  @override
  State<WordSetListPage> createState() => _WordSetListPageState();
}

class _WordSetListPageState extends State<WordSetListPage> {
  late Future<List<WordSet>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repositories.wordSets();
  }

  void _reload() {
    setState(() {
      _future = widget.repositories.wordSets();
    });
  }

  Future<void> _createWordSet() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新建词集'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '词集名称,如:高考词汇'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('创建'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    await widget.repositories.createWordSet(name);
    _reload();
  }

  Future<void> _importWords(WordSet wordSet) async {
    final added = await ImportService.pickAndImport(
      context,
      wordSetId: wordSet.id,
      repositories: widget.repositories,
    );
    if (added != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已导入 $added 个新词')),
      );
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的词集'),
        actions: [
          IconButton(
            tooltip: '新建词集',
            icon: const Icon(Icons.add),
            onPressed: _createWordSet,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createWordSet,
        tooltip: '新建词集',
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<WordSet>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  const Text('数据库加载失败', style: TextStyle(fontSize: 18)),
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
                  FilledButton(onPressed: _reload, child: const Text('重试')),
                ],
              ),
            );
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final sets = snapshot.data ?? const [];
          if (sets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('还没有词集', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  const Text('创建一个词集,然后导入单词表开始学习', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: _createWordSet, child: const Text('创建词集')),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: sets.length,
            itemBuilder: (context, i) {
              final set = sets[i];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(set.name),
                  subtitle: Text('创建于 ${set.createdAt.toLocal().toString().substring(0, 10)}'),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WordListPage(
                          wordSet: set,
                          repositories: widget.repositories,
                        ),
                      ),
                    );
                    _reload();
                  },
                  trailing: IconButton(
                    tooltip: '导入单词',
                    icon: const Icon(Icons.upload_file),
                    onPressed: () => _importWords(set),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
