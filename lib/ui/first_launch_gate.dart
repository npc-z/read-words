import 'package:flutter/material.dart';
import 'package:read_words/data/repositories.dart';
import 'package:read_words/generation/generation_queue.dart';
import 'package:read_words/ui/level_onboarding_page.dart';
import 'package:read_words/ui/word_set_list_page.dart';

/// 首次启动门(§12):英语水平未选择时强制进入引导,选择后进入主界面。
/// 设置读取失败时显示可见报错 + 重试,不静默放行。
class FirstLaunchGate extends StatefulWidget {
  const FirstLaunchGate({
    super.key,
    required this.repositories,
    required this.queue,
  });

  final Repositories repositories;
  final GenerationQueue queue;

  @override
  State<FirstLaunchGate> createState() => _FirstLaunchGateState();
}

class _FirstLaunchGateState extends State<FirstLaunchGate> {
  bool? _hasLevel;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final has = await widget.repositories.hasLevel();
      if (!mounted) return;
      setState(() => _hasLevel = has);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  Widget _buildContent() {
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              const Text('设置加载失败', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  '$_error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: const Text('重试')),
            ],
          ),
        ),
      );
    }
    if (_hasLevel == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_hasLevel!) {
      return WordSetListPage(repositories: widget.repositories, queue: widget.queue);
    }
    return LevelOnboardingPage(repositories: widget.repositories, queue: widget.queue);
  }

  @override
  Widget build(BuildContext context) {
    return _buildContent();
  }
}
