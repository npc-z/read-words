/// 设置域模型(§12)
///
/// 存储格式约定:枚举存 `.name`,整数存字符串;非法值一律回退默认。
library;

/// 英语水平(§12)
enum EnglishLevel {
  gaokao('高考'),
  cet46('四六级'),
  tem48('专四专八');

  const EnglishLevel(this.label);
  final String label;
}

/// 视图模式(§8.1)
enum ViewMode {
  study('学习模式'),
  lookup('查阅模式'),
  review('复习模式');

  const ViewMode(this.label);
  final String label;
}

/// 展示配置(§8.2)
enum DisplayMode {
  both('中英双语'),
  en('仅英文'),
  zh('仅中文');

  const DisplayMode(this.label);
  final String label;
}

/// 设置快照;未持久化的键取默认值
class AppSettings {
  const AppSettings({
    this.level = EnglishLevel.gaokao,
    this.dailyReadingX = 50,
    this.budgetMultiple = 3,
    this.concurrency = 4,
    this.apiKey = '',
    this.defaultViewMode = ViewMode.study,
    this.displayMode = DisplayMode.both,
  });

  /// 英语水平(§4.4 生成参数 + 推荐排序)
  final EnglishLevel level;

  /// 每日阅读量 X(§6.2 预算基数)
  final int dailyReadingX;

  /// 预算倍数 M(§6.2)
  final int budgetMultiple;

  /// 生成并发数(§6.5)
  final int concurrency;

  /// AI API Key(OpenAI 兼容)
  final String apiKey;

  /// 默认视图模式(§8.1)
  final ViewMode defaultViewMode;

  /// 展示配置(§8.2)
  final DisplayMode displayMode;

  AppSettings copyWith({
    EnglishLevel? level,
    int? dailyReadingX,
    int? budgetMultiple,
    int? concurrency,
    String? apiKey,
    ViewMode? defaultViewMode,
    DisplayMode? displayMode,
  }) {
    return AppSettings(
      level: level ?? this.level,
      dailyReadingX: dailyReadingX ?? this.dailyReadingX,
      budgetMultiple: budgetMultiple ?? this.budgetMultiple,
      concurrency: concurrency ?? this.concurrency,
      apiKey: apiKey ?? this.apiKey,
      defaultViewMode: defaultViewMode ?? this.defaultViewMode,
      displayMode: displayMode ?? this.displayMode,
    );
  }
}
