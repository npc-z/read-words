import 'package:flutter/material.dart';
import 'package:read_words/data/db.dart';
import 'package:read_words/data/repositories.dart';
import 'package:read_words/ui/word_set_list_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await openDatabase();
  runApp(ReadWordsApp(repositories: Repositories(db)));
}

class ReadWordsApp extends StatelessWidget {
  const ReadWordsApp({super.key, required this.repositories});

  final Repositories repositories;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '阅读学单词',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        useMaterial3: true,
      ),
      home: WordSetListPage(repositories: repositories),
    );
  }
}
