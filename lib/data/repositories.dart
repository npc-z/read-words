import 'package:drift/drift.dart';
import 'package:read_words/data/app_database.dart';
import 'package:read_words/data/settings.dart';

/// 素材数据(内容层)
class MaterialData {
  const MaterialData({
    required this.sensesJson,
    this.phoneticUk = '',
    this.phoneticUs = '',
    this.phrasesJson = '[]',
    this.unclassifiedExamplesJson = '[]',
    this.rawHtml = '',
    this.source = 'ai',
  });

  final String phoneticUk;
  final String phoneticUs;
  final String sensesJson;
  final String phrasesJson;
  final String unclassifiedExamplesJson;
  final String rawHtml;
  final String source;
}

/// 到期复习词(§8.4):词 + 下次复习时间
class DueReviewWord {
  const DueReviewWord({
    required this.wordId,
    required this.headword,
    required this.nextReviewAt,
  });

  final int wordId;
  final String headword;
  final DateTime nextReviewAt;
}

/// 设置键(§12)
class SettingsKeys {
  static const apiKey = 'apiKey';
  static const level = 'level';
  static const dailyReadingX = 'dailyReadingX';
  static const budgetMultiple = 'budgetMultiple';
  static const concurrency = 'concurrency';
  static const defaultViewMode = 'defaultViewMode';
  static const displayMode = 'displayMode';
  SettingsKeys._();
}

/// 仓储层:词集 / 词(去重)/ 素材 / 复习状态
class Repositories {
  Repositories(this.db);

  final AppDatabase db;

  Future<int> createWordSet(String name) async {
    return db.into(db.wordSets).insert(WordSetsCompanion.insert(name: name));
  }

  Future<List<WordSet>> wordSets() async {
    return db.select(db.wordSets).get();
  }

  Future<List<Word>> wordsInSet(int wordSetId) async {
    return (db.select(db.words)
          ..where((w) => w.wordSetId.equals(wordSetId))
          ..orderBy([(w) => OrderingTerm.asc(w.sortKey)]))
        .get();
  }

  Future<Word?> wordById(int wordId) async {
    return (db.select(db.words)..where((w) => w.id.equals(wordId)))
        .getSingleOrNull();
  }

  Future<void> setWordStatus(int wordId, WordStatus status) async {
    await (db.update(db.words)..where((w) => w.id.equals(wordId)))
        .write(WordsCompanion(status: Value(status.name)));
  }

  /// 批量加词,词集去重:已存在的词跳过,返回实际新增数
  Future<int> addWords(int wordSetId, Iterable<String> headwords) async {
    final existing = await (db.select(db.words)
          ..where((w) => w.wordSetId.equals(wordSetId)))
        .get();
    final known = existing.map((w) => w.headword.toLowerCase()).toSet();

    var added = 0;
    var sortKey = existing.length;
    for (final h in headwords) {
      final word = h.trim().toLowerCase();
      if (word.isEmpty || known.contains(word)) continue;
      await db.into(db.words).insert(WordsCompanion.insert(
            wordSetId: wordSetId,
            headword: word,
            sortKey: Value(sortKey++),
          ));
      known.add(word);
      added++;
    }
    return added;
  }

  Future<void> saveMaterial(int wordId, MaterialData data) async {
    await db.into(db.wordMaterials).insertOnConflictUpdate(
          WordMaterialsCompanion.insert(
            wordId: Value(wordId),
            phoneticUk: Value(data.phoneticUk),
            phoneticUs: Value(data.phoneticUs),
            sensesJson: data.sensesJson,
            phrasesJson: Value(data.phrasesJson),
            unclassifiedExamplesJson: Value(data.unclassifiedExamplesJson),
            rawHtml: Value(data.rawHtml),
            source: Value(data.source),
          ),
        );
  }

  Future<WordMaterial?> materialFor(int wordId) async {
    return (db.select(db.wordMaterials)
          ..where((m) => m.wordId.equals(wordId)))
        .getSingleOrNull();
  }

  Future<ReviewState?> reviewStateFor(int wordId) async {
    return (db.select(db.reviewStatesTable)
          ..where((r) => r.wordId.equals(wordId)))
        .getSingleOrNull();
  }

  /// 标记认识/不认识(§8.4)。首次标记进入轻量复习:间隔置 1,
  /// 次日可复习(nextReviewAt = +1 天);重复标记只更新标记,不重置排期
  Future<void> markKnown(int wordId, {required bool known}) async {
    final now = DateTime.now();
    final existing = await reviewStateFor(wordId);
    final seq = (existing?.deviceSeq ?? 0) + 1;
    await db.into(db.reviewStatesTable).insertOnConflictUpdate(
          ReviewStatesTableCompanion.insert(
            wordId: Value(wordId),
            known: Value(known),
            interval: Value(existing?.interval ?? 1),
            nextReviewAt: Value(
              existing?.nextReviewAt ?? now.add(const Duration(days: 1)),
            ),
            updatedAt: Value(now),
            deviceSeq: Value(seq),
          ),
        );
  }

  /// 复习推进:间隔 1→3→7,并计算下次复习时间;返回推进后的间隔。
  /// (interval 0 为旧版「认识首标」遗留值,仍按 0→1 处理)
  Future<int> advanceReview(int wordId) async {
    final existing = await reviewStateFor(wordId);
    if (existing == null) return 0;
    final next = switch (existing.interval) {
      0 => 1,
      1 => 3,
      _ => 7,
    };
    await db.update(db.reviewStatesTable).replace(
          existing.copyWith(
            interval: next,
            nextReviewAt: Value(DateTime.now().add(Duration(days: next))),
          ),
        );
    return next;
  }

  /// 词集内到期(含逾期)的复习词(§8.4):nextReviewAt 非空且 ≤ 当前时间,
  /// 按到期时间升序;未标记或未到期词不进入
  Future<List<DueReviewWord>> dueReviewWords(int wordSetId) async {
    final now = DateTime.now();
    final query = db.select(db.reviewStatesTable).join([
      innerJoin(db.words, db.words.id.equalsExp(db.reviewStatesTable.wordId)),
    ])
      ..where(
        db.words.wordSetId.equals(wordSetId) &
            db.reviewStatesTable.nextReviewAt.isNotNull() &
            db.reviewStatesTable.nextReviewAt.isSmallerOrEqualValue(now),
      );
    final rows = await query.get();
    final due = <DueReviewWord>[
      for (final row in rows)
        DueReviewWord(
          wordId: row.readTable(db.words).id,
          headword: row.readTable(db.words).headword,
          nextReviewAt: row.readTable(db.reviewStatesTable).nextReviewAt!,
        ),
    ]..sort((a, b) => a.nextReviewAt.compareTo(b.nextReviewAt));
    return due;
  }

  /// 词集内到期复习词数(词列表徽章,§8.4)
  Future<int> dueReviewCount(int wordSetId) async {
    return (await dueReviewWords(wordSetId)).length;
  }

  /// 英语水平是否已选择(§12 首次启动必选):仅当存有合法水平值才算已选。
  /// 未选择或值非法都不产生默认回退,下次启动仍要求进入引导
  Future<bool> hasLevel() async {
    final raw = await getSetting(SettingsKeys.level);
    if (raw == null) return false;
    return EnglishLevel.values.any((level) => level.name == raw);
  }

  /// 读取设置(§12);不存在返回 null
  Future<String?> getSetting(String key) async {
    final row = await (db.select(db.settingsTable)
          ..where((s) => s.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  /// 写入/覆盖设置
  Future<void> setSetting(String key, String value) async {
    await db.into(db.settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion.insert(key: key, value: value),
        );
  }

  /// 读取全部设置,未持久化/非法值回退默认(§12)
  Future<AppSettings> settings() async {
    final rows = await db.select(db.settingsTable).get();
    final raw = {for (final row in rows) row.key: row.value};
    final defaults = const AppSettings();
    return AppSettings(
      level: _enumOr(
        EnglishLevel.values,
        raw[SettingsKeys.level],
        defaults.level,
      ),
      dailyReadingX: _intOr(
        raw[SettingsKeys.dailyReadingX],
        defaults.dailyReadingX,
      ),
      budgetMultiple: _intOr(
        raw[SettingsKeys.budgetMultiple],
        defaults.budgetMultiple,
      ),
      concurrency: _intOr(
        raw[SettingsKeys.concurrency],
        defaults.concurrency,
      ),
      apiKey: raw[SettingsKeys.apiKey] ?? defaults.apiKey,
      defaultViewMode: _enumOr(
        ViewMode.values,
        raw[SettingsKeys.defaultViewMode],
        defaults.defaultViewMode,
      ),
      displayMode: _enumOr(
        DisplayMode.values,
        raw[SettingsKeys.displayMode],
        defaults.displayMode,
      ),
    );
  }

  /// 整批持久化全部设置
  Future<void> saveSettings(AppSettings s) async {
    final rows = {
      SettingsKeys.level: s.level.name,
      SettingsKeys.dailyReadingX: s.dailyReadingX.toString(),
      SettingsKeys.budgetMultiple: s.budgetMultiple.toString(),
      SettingsKeys.concurrency: s.concurrency.toString(),
      SettingsKeys.apiKey: s.apiKey,
      SettingsKeys.defaultViewMode: s.defaultViewMode.name,
      SettingsKeys.displayMode: s.displayMode.name,
    };
    await db.transaction(() async {
      for (final entry in rows.entries) {
        await db.into(db.settingsTable).insertOnConflictUpdate(
              SettingsTableCompanion.insert(
                key: entry.key,
                value: entry.value,
              ),
            );
      }
    });
  }

  /// 预算:某自然日已用额度(§6.2);无记录为 0
  Future<int> budgetUsedOn(String day) async {
    final row = await (db.select(db.budgetDays)
          ..where((r) => r.day.equals(day)))
        .getSingleOrNull();
    return row?.count ?? 0;
  }

  /// 预算:原子累加当日额度(§6.2);并发批次间不丢更新
  Future<void> addBudgetUse(String day, int count) async {
    await db.customStatement(
      'INSERT INTO budget_days (day, count) VALUES (?, ?) '
      'ON CONFLICT(day) DO UPDATE SET count = count + excluded.count',
      [day, count],
    );
  }

  /// 预算:原子预约——事务内查限,未达限则 +1 并返回 true(§6.2 硬上限)
  Future<bool> reserveBudget(String day, int limit) {
    return db.transaction(() async {
      final used = await budgetUsedOn(day);
      if (used >= limit) return false;
      await db.into(db.budgetDays).insertOnConflictUpdate(
            BudgetDaysCompanion.insert(day: day, count: Value(used + 1)),
          );
      return true;
    });
  }

  /// 预算:释放预约(失败/取消的词),下限 0
  Future<void> releaseBudget(String day) async {
    await db.customStatement(
      'UPDATE budget_days SET count = MAX(count - 1, 0) WHERE day = ?',
      [day],
    );
  }

  /// 生成队列:插入任务(词已有待处理任务则忽略;请求即时生成时提升优先级)(§6.1)
  Future<void> insertGenerationTask(int wordId, {required int priority}) async {
    await db.customStatement(
      'INSERT OR IGNORE INTO generation_tasks (word_id, priority) VALUES (?, ?) '
      'ON CONFLICT(word_id) DO UPDATE SET priority = MAX(priority, excluded.priority)',
      [wordId, priority],
    );
  }

  /// 生成队列:归还被领取的任务(预算达限未消费,回 queued)
  Future<void> unclaimGenerationTask(int taskId) async {
    await (db.update(db.generationTasks)
          ..where((t) => t.id.equals(taskId)))
        .write(const GenerationTasksCompanion(state: Value('queued')));
  }

  /// 生成队列:原子领取下一个任务(优先级高先、FIFO),返回已标记 generating 的任务
  Future<GenerationTask?> claimNextGenerationTask() async {
    final rows = await db.customSelect(
      'UPDATE generation_tasks SET state = ? '
      'WHERE id = (SELECT id FROM generation_tasks WHERE state = ? '
      '  ORDER BY priority DESC, id ASC LIMIT 1) '
      'RETURNING id, word_id, priority, queued_at',
      variables: [Variable('generating'), Variable('queued')],
    ).get();
    if (rows.isEmpty) return null;
    final r = rows.single.data;
    return GenerationTask(
      id: r['id'] as int,
      wordId: r['word_id'] as int,
      priority: r['priority'] as int,
      state: 'generating',
      queuedAt: DateTime.fromMillisecondsSinceEpoch(
        (r['queued_at'] as int) * 1000,
      ),
    );
  }

  /// 生成队列:删除任务(结算后)
  Future<void> deleteGenerationTask(int taskId) async {
    await (db.delete(db.generationTasks)..where((t) => t.id.equals(taskId))).go();
  }

  /// 生成队列:按词删除任务
  Future<void> deleteGenerationTaskByWord(int wordId) async {
    await (db.delete(db.generationTasks)
          ..where((t) => t.wordId.equals(wordId)))
        .go();
  }

  /// 生成队列:词集的后台待处理词(取消批次用,§6.1)
  Future<List<int>> backgroundPendingWordIds(int wordSetId) async {
    final rows = await db.customSelect(
      'SELECT t.word_id AS word_id FROM generation_tasks t '
      'JOIN words w ON w.id = t.word_id '
      'WHERE w.word_set_id = ? AND t.priority = 0 AND t.state = ?',
      variables: [Variable(wordSetId), Variable('queued')],
    ).get();
    return [for (final r in rows) r.data['word_id'] as int];
  }

  /// 生成队列:续跑复位——generating 状态的任务视为中断,回 queued(词状态同步)。
  /// 中断的后台任务已预约的预算一并归还,避免续跑重复计账。
  Future<void> resetInterruptedTasks() async {
    await db.transaction(() async {
      // 先归还中断后台任务占用的预算(即时任务不占预算),再复位状态
      await db.customStatement(
        "UPDATE budget_days SET count = MAX(count - (SELECT COUNT(*) "
        "FROM generation_tasks WHERE state = 'generating' AND priority = 0), 0)",
      );
      await db.customStatement(
        "UPDATE generation_tasks SET state = 'queued' WHERE state = 'generating'",
      );
      await (db.update(db.words)
            ..where((w) => w.status.equals('generating')))
          .write(const WordsCompanion(status: Value('queued')));
    });
  }

  /// 生成队列:待处理任务数
  Future<int> pendingGenerationTaskCount() async {
    return db.customSelect(
      'SELECT COUNT(*) AS c FROM generation_tasks',
    ).get().then((rows) => rows.single.data['c'] as int);
  }

  static T _enumOr<T extends Enum>(List<T> values, String? name, T fallback) {
    for (final v in values) {
      if (v.name == name) return v;
    }
    return fallback;
  }

  static int _intOr(String? raw, int fallback) {
    return int.tryParse(raw ?? '') ?? fallback;
  }
}
