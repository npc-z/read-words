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

  /// 标记认识/不认识;首次标记时把间隔置为 1(轻量复习,§8.4)
  Future<void> markKnown(int wordId, {required bool known}) async {
    final now = DateTime.now();
    final existing = await reviewStateFor(wordId);
    final seq = (existing?.deviceSeq ?? 0) + 1;
    await db.into(db.reviewStatesTable).insertOnConflictUpdate(
          ReviewStatesTableCompanion.insert(
            wordId: Value(wordId),
            known: Value(known),
            interval: Value(existing?.interval ?? (known ? 0 : 1)),
            updatedAt: Value(now),
            deviceSeq: Value(seq),
          ),
        );
  }

  /// 复习推进:间隔 1→3→7,并计算下次复习时间
  Future<void> advanceReview(int wordId) async {
    final existing = await reviewStateFor(wordId);
    if (existing == null) return;
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
