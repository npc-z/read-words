import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:read_words/data/app_database.dart';
import 'package:read_words/data/repositories.dart';
import 'package:read_words/data/settings.dart';
import 'package:read_words/generation/content.dart';
import 'package:read_words/generation/generation_queue.dart';

/// 单词详情页(§8:3 个预设视图模式,右上角切换 + 展示配置)。
/// 点开未生成词 → 即时生成(§6.1 最高优先,不受预算限制)。
class WordDetailPage extends StatefulWidget {
  const WordDetailPage({
    super.key,
    required this.word,
    required this.repositories,
    required this.queue,
    this.initialMode,
  });

  final Word word;
  final Repositories repositories;
  final GenerationQueue queue;

  /// 入口指定的初始视图模式(如复习入口);null 时用设置默认值
  final ViewMode? initialMode;

  @override
  State<WordDetailPage> createState() => _WordDetailPageState();
}

class _WordDetailPageState extends State<WordDetailPage> {
  ViewMode _mode = ViewMode.study;

  /// 展示配置(§8.2)
  DisplayMode _display = DisplayMode.both;

  WordMaterial? _material;
  bool _loading = true;
  Object? _loadError;

  /// 词的实时状态(生成过程中由队列驱动刷新)
  String? _wordStatus;
  bool _genRequested = false;

  @override
  void initState() {
    super.initState();
    _wordStatus = widget.word.status;
    widget.queue.addListener(_onQueueChanged);
    _load();
  }

  @override
  void dispose() {
    widget.queue.removeListener(_onQueueChanged);
    super.dispose();
  }

  void _onQueueChanged() {
    if (!mounted) return;
    unawaited(_refresh());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        widget.repositories.materialFor(widget.word.id),
        widget.repositories.settings(),
      ]);
      final m = results[0] as WordMaterial?;
      final settings = results[1] as AppSettings;
      if (mounted) {
        setState(() {
          _material = m;
          _mode = widget.initialMode ?? settings.defaultViewMode;
          _display = settings.displayMode;
          _loading = false;
          _loadError = null;
        });
      }
      // 未生成素材:即时生成(§6.1);生成中/失败重试由 _refresh 处理
      if (m == null && !_genRequested) {
        _genRequested = true;
        unawaited(widget.queue.enqueue(widget.word.id, immediate: true));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = e;
        });
      }
    }
  }

  Future<void> _refresh() async {
    final m = await widget.repositories.materialFor(widget.word.id);
    final w = await widget.repositories.wordById(widget.word.id);
    if (mounted) {
      setState(() {
        _material = m;
        _wordStatus = w?.status;
      });
    }
  }

  Future<void> _retry() async {
    _genRequested = true;
    setState(() {});
    await widget.queue.enqueue(widget.word.id, immediate: true);
  }

  /// 复习标记(§8.3):认识/不认识,首次标记进入轻量复习(次日可复习)
  Future<void> _mark(bool known) async {
    await widget.repositories.markKnown(widget.word.id, known: known);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(known ? '已标记认识' : '已标记不认识')));
  }

  List<Sense> _senses() {
    if (_material == null) return const [];
    final list = jsonDecode(_material!.sensesJson) as List;
    return [
      for (final s in list)
        if (Sense.fromJson(Map<String, dynamic>.from(s as Map)) != null)
          Sense.fromJson(Map<String, dynamic>.from(s))!,
    ];
  }

  List<Phrase> _phrases() {
    if (_material == null) return const [];
    final list = jsonDecode(_material!.phrasesJson) as List;
    return [
      for (final p in list)
        if (Phrase.fromJson(Map<String, dynamic>.from(p as Map)) != null)
          Phrase.fromJson(Map<String, dynamic>.from(p))!,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.word.headword),
        actions: [
          // 展示配置(§8.2)
          PopupMenuButton<DisplayMode>(
            initialValue: _display,
            tooltip: '展示配置',
            onSelected: (v) => setState(() => _display = v),
            itemBuilder: (_) => [
              for (final mode in DisplayMode.values)
                PopupMenuItem(value: mode, child: Text(mode.label)),
            ],
          ),
          // 视图模式切换(§8.1)
          PopupMenuButton<ViewMode>(
            initialValue: _mode,
            tooltip: '视图模式',
            onSelected: (m) => setState(() => _mode = m),
            itemBuilder: (_) => const [
              PopupMenuItem(value: ViewMode.study, child: Text('学习模式')),
              PopupMenuItem(value: ViewMode.lookup, child: Text('查阅模式')),
              PopupMenuItem(value: ViewMode.review, child: Text('复习模式')),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  const Text('加载失败', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: _load, child: const Text('重试')),
                ],
              ),
            )
          : _material != null
          ? switch (_mode) {
              ViewMode.study => _StudyView(
                word: widget.word.headword,
                uk: _material?.phoneticUk ?? '',
                us: _material?.phoneticUs ?? '',
                senses: _senses(),
                phrases: _phrases(),
                display: _display,
              ),
              ViewMode.lookup => _LookupView(
                word: widget.word.headword,
                uk: _material?.phoneticUk ?? '',
                us: _material?.phoneticUs ?? '',
                senses: _senses(),
                phrases: _phrases(),
                display: _display,
              ),
              ViewMode.review => _ReviewView(
                senses: _senses(),
                display: _display,
              ),
            }
          : _GenerationPlaceholder(status: _wordStatus, onRetry: _retry),
      // 复习标记栏(§8.3):素材就绪时可用
      bottomNavigationBar: _material != null
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.close),
                        label: const Text('不认识'),
                        onPressed: () => _mark(false),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.check),
                        label: const Text('认识'),
                        onPressed: () => _mark(true),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}

/// 素材未生成时的占位:即时生成中 / 失败重试 / 手动生成(§6.1)
class _GenerationPlaceholder extends StatelessWidget {
  const _GenerationPlaceholder({required this.status, required this.onRetry});

  final String? status;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (status == WordStatus.queued.name ||
        status == WordStatus.generating.name) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 16),
            const Text('正在即时生成,请稍候…'),
            const SizedBox(height: 4),
            const Text(
              '即时生成优先于后台批次,不受预算限制',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }
    if (status == WordStatus.failed.name) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            const Text('生成失败', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      );
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('该单词尚未生成素材'),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('生成')),
        ],
      ),
    );
  }
}

/// 音标行
class _PhoneticHeader extends StatelessWidget {
  const _PhoneticHeader({
    required this.word,
    required this.uk,
    required this.us,
  });

  final String word;
  final String uk;
  final String us;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                word,
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: '英音',
                icon: const Icon(Icons.volume_up),
                onPressed: () => _speak(word, 'en-GB'),
              ),
              IconButton(
                tooltip: '美音',
                icon: const Icon(Icons.volume_up_outlined),
                onPressed: () => _speak(word, 'en-US'),
              ),
            ],
          ),
          Text(
            '英 ${uk.isEmpty ? '—' : uk}    美 ${us.isEmpty ? '—' : us}',
            style: const TextStyle(color: Colors.grey, fontSize: 15),
          ),
        ],
      ),
    );
  }

  void _speak(String text, String lang) {
    // TTS 合成由 flutter_tts 接入(§10.3),此处先占位
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge(this.level);

  final int level;

  @override
  Widget build(BuildContext context) {
    final color = switch (level) {
      1 => const Color(0xFF22C55E),
      2 => const Color(0xFFF59E0B),
      _ => const Color(0xFFEF4444),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'L$level',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// 例句行(受展示配置控制,§8.2)
class _ExampleRow extends StatelessWidget {
  const _ExampleRow({required this.example, required this.display});

  final Example example;
  final DisplayMode display;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: _LevelBadge(example.level),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: display == DisplayMode.zh
                    ? const SizedBox.shrink()
                    : Text(
                        example.en,
                        style: const TextStyle(fontSize: 15, height: 1.5),
                      ),
              ),
            ],
          ),
          if (display != DisplayMode.en)
            Padding(
              padding: const EdgeInsets.only(left: 34, top: 2),
              child: Text(
                example.zh,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}

/// 学习模式:分层阅读流(原型 A,§8.1)
class _StudyView extends StatelessWidget {
  const _StudyView({
    required this.word,
    required this.uk,
    required this.us,
    required this.senses,
    required this.phrases,
    required this.display,
  });

  final String word;
  final String uk;
  final String us;
  final List<Sense> senses;
  final List<Phrase> phrases;
  final DisplayMode display;

  @override
  Widget build(BuildContext context) {
    final all = [for (final s in senses) ...s.examples];
    final byLevel = {
      1: all.where((e) => e.level == 1).toList(),
      2: all.where((e) => e.level == 2).toList(),
      3: all.where((e) => e.level == 3).toList(),
    };
    final names = const {1: '简单句 · 核心用法', 2: '从句与搭配', 3: '复合句与书面语'};

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _PhoneticHeader(word: word, uk: uk, us: us),
        for (final lvl in [1, 2, 3]) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Row(
              children: [
                _LevelBadge(lvl),
                const SizedBox(width: 8),
                Text(
                  names[lvl]!,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  '${byLevel[lvl]!.length}/3',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                children: [
                  for (final e in byLevel[lvl]!)
                    _ExampleRow(example: e, display: display),
                ],
              ),
            ),
          ),
        ],
        if (phrases.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Text(
              '常用短语',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          for (final p in phrases)
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: ListTile(
                title: Text(
                  p.phrase,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.en),
                    if (display != DisplayMode.en)
                      Text(
                        p.zh,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}

/// 查阅模式:词典式(原型 B,§8.1)
class _LookupView extends StatelessWidget {
  const _LookupView({
    required this.word,
    required this.uk,
    required this.us,
    required this.senses,
    required this.phrases,
    required this.display,
  });

  final String word;
  final String uk;
  final String us;
  final List<Sense> senses;
  final List<Phrase> phrases;
  final DisplayMode display;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _PhoneticHeader(word: word, uk: uk, us: us),
        for (final s in senses) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Text(
              s.pos,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.meaning, style: const TextStyle(fontSize: 15)),
                  const Divider(height: 20),
                  for (final e in s.examples)
                    _ExampleRow(example: e, display: display),
                ],
              ),
            ),
          ),
        ],
        if (phrases.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Text(
              '常用短语',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          for (final p in phrases)
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: ListTile(title: Text(p.phrase), subtitle: Text(p.en)),
            ),
        ],
      ],
    );
  }
}

/// 复习模式:逐句精读器(原型 C,§8.1)
class _ReviewView extends StatefulWidget {
  const _ReviewView({required this.senses, required this.display});

  final List<Sense> senses;
  final DisplayMode display;

  @override
  State<_ReviewView> createState() => _ReviewViewState();
}

class _ReviewViewState extends State<_ReviewView> {
  int _index = 0;

  List<Example> get _all => [for (final s in widget.senses) ...s.examples];

  @override
  Widget build(BuildContext context) {
    final all = _all;
    if (all.isEmpty) return const Center(child: Text('暂无例句'));
    final current = all[_index % all.length];

    return Column(
      children: [
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < all.length; i++)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == _index
                      ? Colors.blue
                      : switch (all[i].level) {
                          1 => const Color(0xFF22C55E),
                          2 => const Color(0xFFF59E0B),
                          _ => const Color(0xFFEF4444),
                        },
                ),
              ),
          ],
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _LevelBadge(current.level),
                  const SizedBox(height: 16),
                  if (widget.display != DisplayMode.zh)
                    Text(
                      current.en,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20, height: 1.6),
                    ),
                  if (widget.display != DisplayMode.en)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        current.zh,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 15,
                          height: 1.6,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              iconSize: 40,
              icon: const Icon(Icons.chevron_left),
              onPressed: () => setState(
                () => _index = (_index - 1 + all.length) % all.length,
              ),
            ),
            IconButton(
              iconSize: 40,
              icon: const Icon(Icons.chevron_right),
              onPressed: () =>
                  setState(() => _index = (_index + 1) % all.length),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
