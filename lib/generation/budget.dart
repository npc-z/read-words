/// 预算账本(§6.2):后台预生成按本地自然日记账,上限 = M×X。
library;

import 'package:read_words/data/repositories.dart';

/// 今日预算快照
class BudgetState {
  const BudgetState({required this.used, required this.limit});

  final int used;
  final int limit;

  bool get exhausted => used >= limit;
}

/// 预算账本:只约束后台预生成;即时生成不经由此类。
///
/// 自然日按本地时区切分,持久化于 SQLite(重启保留);跨日即隐式重置。
class BudgetLedger {
  BudgetLedger({required this.repositories, DateTime Function()? now})
    : _now = now ?? defaultNow;

  final Repositories repositories;
  final DateTime Function() _now;

  static DateTime defaultNow() => DateTime.now();

  /// 自然日键:'yyyy-MM-dd'(本地时区)
  static String dayOf(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)}';
  }

  /// 今日已用 + 限额(限额 = M×X,来自设置 §12;至少为 1)
  Future<BudgetState> state() async {
    final used = await repositories.budgetUsedOn(dayOf(_now()));
    return BudgetState(used: used, limit: await _limit());
  }

  Future<int> _limit() async {
    final settings = await repositories.settings();
    return (settings.dailyReadingX * settings.budgetMultiple).clamp(1, 1 << 31);
  }

  /// 已达今日上限
  Future<bool> exhausted() async {
    return (await state()).exhausted;
  }

  /// 原子预约一个生成额度:未达限则 +1 并返回 true,已达限返回 false。
  /// 并发下精确(事务串行),超限预约不记账(§6.2 硬上限)。
  Future<bool> reserve() async {
    return repositories.reserveBudget(dayOf(_now()), await _limit());
  }

  /// 释放预约(失败/取消的词),下限 0。
  Future<void> release() async {
    await repositories.releaseBudget(dayOf(_now()));
  }
}
