import 'package:flutter/material.dart';
import 'package:read_words/data/repositories.dart';
import 'package:read_words/data/settings.dart';
import 'package:read_words/generation/generation_queue.dart';
import 'package:read_words/ui/word_set_list_page.dart';

/// 首次启动引导页(§12):英语水平必选,选择即持久化并进入主界面,不可跳过。
/// 未选择直接退出(关 App)不产生默认值,下次启动仍会要求选择。
class LevelOnboardingPage extends StatefulWidget {
  const LevelOnboardingPage({
    super.key,
    required this.repositories,
    required this.queue,
  });

  final Repositories repositories;
  final GenerationQueue queue;

  @override
  State<LevelOnboardingPage> createState() => _LevelOnboardingPageState();
}

class _LevelOnboardingPageState extends State<LevelOnboardingPage> {
  bool _saving = false;

  Future<void> _choose(EnglishLevel level) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await widget.repositories.saveSettings(
        const AppSettings().copyWith(level: level),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => WordSetListPage(
            repositories: widget.repositories,
            queue: widget.queue,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('英语水平保存失败,请重试:${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.school,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              const Text(
                '欢迎使用阅读学单词',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '首次使用,请选择你的英语水平(生成内容按此调整,之后可在设置中修改)',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              SegmentedButton<EnglishLevel>(
                segments: [
                  for (final level in EnglishLevel.values)
                    ButtonSegment(value: level, label: Text(level.label)),
                ],
                selected: const {},
                emptySelectionAllowed: true,
                onSelectionChanged: (selection) => _choose(selection.first),
              ),
              if (_saving) ...[
                const SizedBox(height: 24),
                const Center(child: CircularProgressIndicator()),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
