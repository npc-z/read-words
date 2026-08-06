import 'package:drift/drift.dart';

part 'app_database.g.dart';

/// 词条生成状态(规格书 §3)
enum WordStatus {
  notGenerated('未生成'),
  queued('排队中'),
  generating('生成中'),
  done('已完成'),
  failed('失败');

  const WordStatus(this.label);
  final String label;
}

@DataClassName('WordSet')
class WordSets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('Word')
class Words extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get wordSetId => integer().references(WordSets, #id)();
  TextColumn get headword => text()();

  /// 素材来源:mdx / txt / csv / excel / markdown / ecdict
  TextColumn get source => text().withDefault(const Constant(''))();
  TextColumn get sourceName => text().withDefault(const Constant(''))();

  /// 生成状态(WordStatus.name)
  TextColumn get status => text().withDefault(const Constant('notGenerated'))();
  IntColumn get sortKey => integer().withDefault(const Constant(0))();
}

/// 词素材(内容层,规格书 §4 schema + §5 拼接规则)
@DataClassName('WordMaterial')
class WordMaterials extends Table {
  IntColumn get wordId => integer().references(Words, #id)();
  TextColumn get phoneticUk => text().withDefault(const Constant(''))();
  TextColumn get phoneticUs => text().withDefault(const Constant(''))();

  /// senses 的 JSON(§4.1 schema)
  TextColumn get sensesJson => text()();

  /// phrases 的 JSON(§4.1 schema)
  TextColumn get phrasesJson => text().withDefault(const Constant('[]'))();

  /// 未归类例句的 JSON(§4.2)
  TextColumn get unclassifiedExamplesJson =>
      text().withDefault(const Constant('[]'))();

  /// 原始释义素材(rawHtml,供 AI 提取,调研票建议保留)
  TextColumn get rawHtml => text().withDefault(const Constant(''))();

  /// 素材来源:mdx / ecdict / ai
  TextColumn get source => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {wordId};
}

/// 音频缓存(§10.3 TTS + §7.2 MDD 懒提取)
class AudioCaches extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get wordId => integer().references(Words, #id)();
  TextColumn get variant => text()(); // uk / us

  /// 音频来源:tts / mdd
  TextColumn get origin => text()();
  TextColumn get path => text()();
  TextColumn get format => text()();
}

/// 复习状态(个人层,§8.4 + §9.1 同步对象)
@DataClassName('ReviewState')
class ReviewStatesTable extends Table {
  IntColumn get wordId => integer().references(Words, #id)();
  BoolColumn get known => boolean().withDefault(const Constant(false))();

  /// 间隔天数:1/3/7
  IntColumn get interval => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextReviewAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  /// 设备逻辑序号,用于 LWW 冲突解决(§9.1)
  IntColumn get deviceSeq => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {wordId};
}

/// 待发队列(断线改动,§9.1 离线边界)
class PendingQueues extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get kind => text()(); // generation / import / sync
  TextColumn get payload => text()();
  TextColumn get state => text().withDefault(const Constant('pending'))();
}

/// 设置(§12)
class SettingsTable extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// 预算账本(§6.2):按本地自然日统计后台生成词数
@DataClassName('BudgetDay')
class BudgetDays extends Table {
  /// 自然日,格式 'yyyy-MM-dd'(本地时区)
  TextColumn get day => text()();
  IntColumn get count => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {day};
}

/// 生成任务队列(§6.1 单队列双优先级):行存在即待处理
@DataClassName('GenerationTask')
class GenerationTasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get wordId => integer().references(Words, #id).unique()();
  IntColumn get priority => integer()(); // 0=后台预生成 1=即时生成
  TextColumn get state =>
      text().withDefault(const Constant('queued'))(); // queued/generating
  DateTimeColumn get queuedAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(
  tables: [
    WordSets,
    Words,
    WordMaterials,
    AudioCaches,
    ReviewStatesTable,
    PendingQueues,
    SettingsTable,
    BudgetDays,
    GenerationTasks,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // v1 的 settings_table 无主键;settings 尚无任何数据,重建即可
        await m.drop(settingsTable);
        await m.create(settingsTable);
      }
      if (from < 3) {
        // v2 无预算表,新建即可
        await m.create(budgetDays);
      }
      if (from < 4) {
        // v3 无生成任务表,新建即可
        await m.create(generationTasks);
      }
    },
  );
}
