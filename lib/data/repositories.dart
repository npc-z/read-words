import 'package:drift/drift.dart';
import 'package:read_words/data/app_database.dart';

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
}
