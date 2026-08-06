import 'package:flutter/material.dart';
import 'package:read_words/data/repositories.dart';
import 'package:read_words/data/settings.dart';

/// 设置页(§12):全部设置项可编辑,改动立即持久化
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.repositories});

  final Repositories repositories;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  AppSettings _settings = const AppSettings();
  bool _loaded = false;
  Object? _error;

  late final TextEditingController _xController;
  late final TextEditingController _mController;
  late final TextEditingController _concurrencyController;
  late final TextEditingController _apiKeyController;
  late final FocusNode _xFocus;
  late final FocusNode _mFocus;
  late final FocusNode _concurrencyFocus;
  bool _obscureKey = true;

  @override
  void initState() {
    super.initState();
    _xController = TextEditingController(text: '${_settings.dailyReadingX}');
    _mController = TextEditingController(text: '${_settings.budgetMultiple}');
    _concurrencyController = TextEditingController(
      text: '${_settings.concurrency}',
    );
    _apiKeyController = TextEditingController(text: _settings.apiKey);
    _xFocus = FocusNode()..addListener(_onXFocusChanged);
    _mFocus = FocusNode()..addListener(_onMFocusChanged);
    _concurrencyFocus = FocusNode()..addListener(_onConcurrencyFocusChanged);
    _load();
  }

  @override
  void dispose() {
    _xController.dispose();
    _mController.dispose();
    _concurrencyController.dispose();
    _apiKeyController.dispose();
    _xFocus.dispose();
    _mFocus.dispose();
    _concurrencyFocus.dispose();
    super.dispose();
  }

  void _onXFocusChanged() =>
      _revertIfInvalid(_xFocus, _xController, _settings.dailyReadingX);
  void _onMFocusChanged() =>
      _revertIfInvalid(_mFocus, _mController, _settings.budgetMultiple);
  void _onConcurrencyFocusChanged() => _revertIfInvalid(
    _concurrencyFocus,
    _concurrencyController,
    _settings.concurrency,
  );

  /// 失焦时非法输入回退为当前持久化值,避免显示与存储分叉
  void _revertIfInvalid(
    FocusNode node,
    TextEditingController controller,
    int current,
  ) {
    if (node.hasFocus) return;
    final n = int.tryParse(controller.text.trim());
    if (n == null || n < 1) {
      controller.text = '$current';
    }
  }

  Future<void> _load() async {
    try {
      final s = await widget.repositories.settings();
      if (!mounted) return;
      setState(() {
        _settings = s;
        _xController.text = '${s.dailyReadingX}';
        _mController.text = '${s.budgetMultiple}';
        _concurrencyController.text = '${s.concurrency}';
        _apiKeyController.text = s.apiKey;
        _loaded = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  Future<void> _save(AppSettings updated) async {
    setState(() => _settings = updated);
    try {
      await widget.repositories.saveSettings(updated);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('设置保存失败:${e.toString()}')));
    }
  }

  Widget _numberField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required int current,
    required AppSettings Function(int n) update,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
      onChanged: (text) {
        final n = int.tryParse(text.trim());
        if (n == null || n < 1) return;
        _save(update(n));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: _error != null
          ? Center(
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
            )
          : !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  '英语水平',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SegmentedButton<EnglishLevel>(
                  segments: [
                    for (final level in EnglishLevel.values)
                      ButtonSegment(value: level, label: Text(level.label)),
                  ],
                  selected: {_settings.level},
                  onSelectionChanged: (selection) =>
                      _save(_settings.copyWith(level: selection.first)),
                ),
                const SizedBox(height: 24),
                _numberField(
                  controller: _xController,
                  focusNode: _xFocus,
                  label: '每日阅读量 X(每天学的词数,预算基数)',
                  current: _settings.dailyReadingX,
                  update: (n) => _settings.copyWith(dailyReadingX: n),
                ),
                const SizedBox(height: 16),
                _numberField(
                  controller: _mController,
                  focusNode: _mFocus,
                  label: '预算倍数 M(后台预生成 = M × X 词)',
                  current: _settings.budgetMultiple,
                  update: (n) => _settings.copyWith(budgetMultiple: n),
                ),
                const SizedBox(height: 16),
                _numberField(
                  controller: _concurrencyController,
                  focusNode: _concurrencyFocus,
                  label: '生成并发数',
                  current: _settings.concurrency,
                  update: (n) => _settings.copyWith(concurrency: n),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _apiKeyController,
                  obscureText: _obscureKey,
                  decoration: InputDecoration(
                    labelText: 'AI API Key(OpenAI 兼容)',
                    suffixIcon: IconButton(
                      tooltip: '显示/隐藏',
                      icon: Icon(
                        _obscureKey ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () =>
                          setState(() => _obscureKey = !_obscureKey),
                    ),
                  ),
                  onChanged: (text) =>
                      _save(_settings.copyWith(apiKey: text.trim())),
                ),
                const SizedBox(height: 24),
                DropdownButtonFormField<ViewMode>(
                  initialValue: _settings.defaultViewMode,
                  decoration: const InputDecoration(labelText: '默认视图模式'),
                  items: [
                    for (final mode in ViewMode.values)
                      DropdownMenuItem(value: mode, child: Text(mode.label)),
                  ],
                  onChanged: (mode) {
                    if (mode != null) {
                      _save(_settings.copyWith(defaultViewMode: mode));
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<DisplayMode>(
                  initialValue: _settings.displayMode,
                  decoration: const InputDecoration(labelText: '展示配置(例句区)'),
                  items: [
                    for (final mode in DisplayMode.values)
                      DropdownMenuItem(value: mode, child: Text(mode.label)),
                  ],
                  onChanged: (mode) {
                    if (mode != null) {
                      _save(_settings.copyWith(displayMode: mode));
                    }
                  },
                ),
              ],
            ),
    );
  }
}
