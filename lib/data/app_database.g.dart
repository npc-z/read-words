// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $WordSetsTable extends WordSets with TableInfo<$WordSetsTable, WordSet> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordSetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'word_sets';
  @override
  VerificationContext validateIntegrity(
    Insertable<WordSet> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WordSet map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WordSet(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $WordSetsTable createAlias(String alias) {
    return $WordSetsTable(attachedDatabase, alias);
  }
}

class WordSet extends DataClass implements Insertable<WordSet> {
  final int id;
  final String name;
  final DateTime createdAt;
  const WordSet({
    required this.id,
    required this.name,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  WordSetsCompanion toCompanion(bool nullToAbsent) {
    return WordSetsCompanion(
      id: Value(id),
      name: Value(name),
      createdAt: Value(createdAt),
    );
  }

  factory WordSet.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WordSet(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  WordSet copyWith({int? id, String? name, DateTime? createdAt}) => WordSet(
    id: id ?? this.id,
    name: name ?? this.name,
    createdAt: createdAt ?? this.createdAt,
  );
  WordSet copyWithCompanion(WordSetsCompanion data) {
    return WordSet(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WordSet(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WordSet &&
          other.id == this.id &&
          other.name == this.name &&
          other.createdAt == this.createdAt);
}

class WordSetsCompanion extends UpdateCompanion<WordSet> {
  final Value<int> id;
  final Value<String> name;
  final Value<DateTime> createdAt;
  const WordSetsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  WordSetsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.createdAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<WordSet> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  WordSetsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<DateTime>? createdAt,
  }) {
    return WordSetsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordSetsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $WordsTable extends Words with TableInfo<$WordsTable, Word> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _wordSetIdMeta = const VerificationMeta(
    'wordSetId',
  );
  @override
  late final GeneratedColumn<int> wordSetId = GeneratedColumn<int>(
    'word_set_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES word_sets (id)',
    ),
  );
  static const VerificationMeta _headwordMeta = const VerificationMeta(
    'headword',
  );
  @override
  late final GeneratedColumn<String> headword = GeneratedColumn<String>(
    'headword',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _sourceNameMeta = const VerificationMeta(
    'sourceName',
  );
  @override
  late final GeneratedColumn<String> sourceName = GeneratedColumn<String>(
    'source_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('notGenerated'),
  );
  static const VerificationMeta _sortKeyMeta = const VerificationMeta(
    'sortKey',
  );
  @override
  late final GeneratedColumn<int> sortKey = GeneratedColumn<int>(
    'sort_key',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    wordSetId,
    headword,
    source,
    sourceName,
    status,
    sortKey,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'words';
  @override
  VerificationContext validateIntegrity(
    Insertable<Word> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('word_set_id')) {
      context.handle(
        _wordSetIdMeta,
        wordSetId.isAcceptableOrUnknown(data['word_set_id']!, _wordSetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_wordSetIdMeta);
    }
    if (data.containsKey('headword')) {
      context.handle(
        _headwordMeta,
        headword.isAcceptableOrUnknown(data['headword']!, _headwordMeta),
      );
    } else if (isInserting) {
      context.missing(_headwordMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('source_name')) {
      context.handle(
        _sourceNameMeta,
        sourceName.isAcceptableOrUnknown(data['source_name']!, _sourceNameMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('sort_key')) {
      context.handle(
        _sortKeyMeta,
        sortKey.isAcceptableOrUnknown(data['sort_key']!, _sortKeyMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Word map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Word(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      wordSetId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}word_set_id'],
      )!,
      headword: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}headword'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      sourceName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_name'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      sortKey: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_key'],
      )!,
    );
  }

  @override
  $WordsTable createAlias(String alias) {
    return $WordsTable(attachedDatabase, alias);
  }
}

class Word extends DataClass implements Insertable<Word> {
  final int id;
  final int wordSetId;
  final String headword;

  /// 素材来源:mdx / txt / csv / excel / markdown / ecdict
  final String source;
  final String sourceName;

  /// 生成状态(WordStatus.name)
  final String status;
  final int sortKey;
  const Word({
    required this.id,
    required this.wordSetId,
    required this.headword,
    required this.source,
    required this.sourceName,
    required this.status,
    required this.sortKey,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['word_set_id'] = Variable<int>(wordSetId);
    map['headword'] = Variable<String>(headword);
    map['source'] = Variable<String>(source);
    map['source_name'] = Variable<String>(sourceName);
    map['status'] = Variable<String>(status);
    map['sort_key'] = Variable<int>(sortKey);
    return map;
  }

  WordsCompanion toCompanion(bool nullToAbsent) {
    return WordsCompanion(
      id: Value(id),
      wordSetId: Value(wordSetId),
      headword: Value(headword),
      source: Value(source),
      sourceName: Value(sourceName),
      status: Value(status),
      sortKey: Value(sortKey),
    );
  }

  factory Word.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Word(
      id: serializer.fromJson<int>(json['id']),
      wordSetId: serializer.fromJson<int>(json['wordSetId']),
      headword: serializer.fromJson<String>(json['headword']),
      source: serializer.fromJson<String>(json['source']),
      sourceName: serializer.fromJson<String>(json['sourceName']),
      status: serializer.fromJson<String>(json['status']),
      sortKey: serializer.fromJson<int>(json['sortKey']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'wordSetId': serializer.toJson<int>(wordSetId),
      'headword': serializer.toJson<String>(headword),
      'source': serializer.toJson<String>(source),
      'sourceName': serializer.toJson<String>(sourceName),
      'status': serializer.toJson<String>(status),
      'sortKey': serializer.toJson<int>(sortKey),
    };
  }

  Word copyWith({
    int? id,
    int? wordSetId,
    String? headword,
    String? source,
    String? sourceName,
    String? status,
    int? sortKey,
  }) => Word(
    id: id ?? this.id,
    wordSetId: wordSetId ?? this.wordSetId,
    headword: headword ?? this.headword,
    source: source ?? this.source,
    sourceName: sourceName ?? this.sourceName,
    status: status ?? this.status,
    sortKey: sortKey ?? this.sortKey,
  );
  Word copyWithCompanion(WordsCompanion data) {
    return Word(
      id: data.id.present ? data.id.value : this.id,
      wordSetId: data.wordSetId.present ? data.wordSetId.value : this.wordSetId,
      headword: data.headword.present ? data.headword.value : this.headword,
      source: data.source.present ? data.source.value : this.source,
      sourceName: data.sourceName.present
          ? data.sourceName.value
          : this.sourceName,
      status: data.status.present ? data.status.value : this.status,
      sortKey: data.sortKey.present ? data.sortKey.value : this.sortKey,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Word(')
          ..write('id: $id, ')
          ..write('wordSetId: $wordSetId, ')
          ..write('headword: $headword, ')
          ..write('source: $source, ')
          ..write('sourceName: $sourceName, ')
          ..write('status: $status, ')
          ..write('sortKey: $sortKey')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, wordSetId, headword, source, sourceName, status, sortKey);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Word &&
          other.id == this.id &&
          other.wordSetId == this.wordSetId &&
          other.headword == this.headword &&
          other.source == this.source &&
          other.sourceName == this.sourceName &&
          other.status == this.status &&
          other.sortKey == this.sortKey);
}

class WordsCompanion extends UpdateCompanion<Word> {
  final Value<int> id;
  final Value<int> wordSetId;
  final Value<String> headword;
  final Value<String> source;
  final Value<String> sourceName;
  final Value<String> status;
  final Value<int> sortKey;
  const WordsCompanion({
    this.id = const Value.absent(),
    this.wordSetId = const Value.absent(),
    this.headword = const Value.absent(),
    this.source = const Value.absent(),
    this.sourceName = const Value.absent(),
    this.status = const Value.absent(),
    this.sortKey = const Value.absent(),
  });
  WordsCompanion.insert({
    this.id = const Value.absent(),
    required int wordSetId,
    required String headword,
    this.source = const Value.absent(),
    this.sourceName = const Value.absent(),
    this.status = const Value.absent(),
    this.sortKey = const Value.absent(),
  }) : wordSetId = Value(wordSetId),
       headword = Value(headword);
  static Insertable<Word> custom({
    Expression<int>? id,
    Expression<int>? wordSetId,
    Expression<String>? headword,
    Expression<String>? source,
    Expression<String>? sourceName,
    Expression<String>? status,
    Expression<int>? sortKey,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (wordSetId != null) 'word_set_id': wordSetId,
      if (headword != null) 'headword': headword,
      if (source != null) 'source': source,
      if (sourceName != null) 'source_name': sourceName,
      if (status != null) 'status': status,
      if (sortKey != null) 'sort_key': sortKey,
    });
  }

  WordsCompanion copyWith({
    Value<int>? id,
    Value<int>? wordSetId,
    Value<String>? headword,
    Value<String>? source,
    Value<String>? sourceName,
    Value<String>? status,
    Value<int>? sortKey,
  }) {
    return WordsCompanion(
      id: id ?? this.id,
      wordSetId: wordSetId ?? this.wordSetId,
      headword: headword ?? this.headword,
      source: source ?? this.source,
      sourceName: sourceName ?? this.sourceName,
      status: status ?? this.status,
      sortKey: sortKey ?? this.sortKey,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (wordSetId.present) {
      map['word_set_id'] = Variable<int>(wordSetId.value);
    }
    if (headword.present) {
      map['headword'] = Variable<String>(headword.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (sourceName.present) {
      map['source_name'] = Variable<String>(sourceName.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (sortKey.present) {
      map['sort_key'] = Variable<int>(sortKey.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordsCompanion(')
          ..write('id: $id, ')
          ..write('wordSetId: $wordSetId, ')
          ..write('headword: $headword, ')
          ..write('source: $source, ')
          ..write('sourceName: $sourceName, ')
          ..write('status: $status, ')
          ..write('sortKey: $sortKey')
          ..write(')'))
        .toString();
  }
}

class $WordMaterialsTable extends WordMaterials
    with TableInfo<$WordMaterialsTable, WordMaterial> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordMaterialsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _wordIdMeta = const VerificationMeta('wordId');
  @override
  late final GeneratedColumn<int> wordId = GeneratedColumn<int>(
    'word_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES words (id)',
    ),
  );
  static const VerificationMeta _phoneticUkMeta = const VerificationMeta(
    'phoneticUk',
  );
  @override
  late final GeneratedColumn<String> phoneticUk = GeneratedColumn<String>(
    'phonetic_uk',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _phoneticUsMeta = const VerificationMeta(
    'phoneticUs',
  );
  @override
  late final GeneratedColumn<String> phoneticUs = GeneratedColumn<String>(
    'phonetic_us',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _sensesJsonMeta = const VerificationMeta(
    'sensesJson',
  );
  @override
  late final GeneratedColumn<String> sensesJson = GeneratedColumn<String>(
    'senses_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phrasesJsonMeta = const VerificationMeta(
    'phrasesJson',
  );
  @override
  late final GeneratedColumn<String> phrasesJson = GeneratedColumn<String>(
    'phrases_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _unclassifiedExamplesJsonMeta =
      const VerificationMeta('unclassifiedExamplesJson');
  @override
  late final GeneratedColumn<String> unclassifiedExamplesJson =
      GeneratedColumn<String>(
        'unclassified_examples_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      );
  static const VerificationMeta _rawHtmlMeta = const VerificationMeta(
    'rawHtml',
  );
  @override
  late final GeneratedColumn<String> rawHtml = GeneratedColumn<String>(
    'raw_html',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    wordId,
    phoneticUk,
    phoneticUs,
    sensesJson,
    phrasesJson,
    unclassifiedExamplesJson,
    rawHtml,
    source,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'word_materials';
  @override
  VerificationContext validateIntegrity(
    Insertable<WordMaterial> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('word_id')) {
      context.handle(
        _wordIdMeta,
        wordId.isAcceptableOrUnknown(data['word_id']!, _wordIdMeta),
      );
    }
    if (data.containsKey('phonetic_uk')) {
      context.handle(
        _phoneticUkMeta,
        phoneticUk.isAcceptableOrUnknown(data['phonetic_uk']!, _phoneticUkMeta),
      );
    }
    if (data.containsKey('phonetic_us')) {
      context.handle(
        _phoneticUsMeta,
        phoneticUs.isAcceptableOrUnknown(data['phonetic_us']!, _phoneticUsMeta),
      );
    }
    if (data.containsKey('senses_json')) {
      context.handle(
        _sensesJsonMeta,
        sensesJson.isAcceptableOrUnknown(data['senses_json']!, _sensesJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_sensesJsonMeta);
    }
    if (data.containsKey('phrases_json')) {
      context.handle(
        _phrasesJsonMeta,
        phrasesJson.isAcceptableOrUnknown(
          data['phrases_json']!,
          _phrasesJsonMeta,
        ),
      );
    }
    if (data.containsKey('unclassified_examples_json')) {
      context.handle(
        _unclassifiedExamplesJsonMeta,
        unclassifiedExamplesJson.isAcceptableOrUnknown(
          data['unclassified_examples_json']!,
          _unclassifiedExamplesJsonMeta,
        ),
      );
    }
    if (data.containsKey('raw_html')) {
      context.handle(
        _rawHtmlMeta,
        rawHtml.isAcceptableOrUnknown(data['raw_html']!, _rawHtmlMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {wordId};
  @override
  WordMaterial map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WordMaterial(
      wordId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}word_id'],
      )!,
      phoneticUk: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phonetic_uk'],
      )!,
      phoneticUs: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phonetic_us'],
      )!,
      sensesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}senses_json'],
      )!,
      phrasesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phrases_json'],
      )!,
      unclassifiedExamplesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unclassified_examples_json'],
      )!,
      rawHtml: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_html'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
    );
  }

  @override
  $WordMaterialsTable createAlias(String alias) {
    return $WordMaterialsTable(attachedDatabase, alias);
  }
}

class WordMaterial extends DataClass implements Insertable<WordMaterial> {
  final int wordId;
  final String phoneticUk;
  final String phoneticUs;

  /// senses 的 JSON(§4.1 schema)
  final String sensesJson;

  /// phrases 的 JSON(§4.1 schema)
  final String phrasesJson;

  /// 未归类例句的 JSON(§4.2)
  final String unclassifiedExamplesJson;

  /// 原始释义素材(rawHtml,供 AI 提取,调研票建议保留)
  final String rawHtml;

  /// 素材来源:mdx / ecdict / ai
  final String source;
  const WordMaterial({
    required this.wordId,
    required this.phoneticUk,
    required this.phoneticUs,
    required this.sensesJson,
    required this.phrasesJson,
    required this.unclassifiedExamplesJson,
    required this.rawHtml,
    required this.source,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['word_id'] = Variable<int>(wordId);
    map['phonetic_uk'] = Variable<String>(phoneticUk);
    map['phonetic_us'] = Variable<String>(phoneticUs);
    map['senses_json'] = Variable<String>(sensesJson);
    map['phrases_json'] = Variable<String>(phrasesJson);
    map['unclassified_examples_json'] = Variable<String>(
      unclassifiedExamplesJson,
    );
    map['raw_html'] = Variable<String>(rawHtml);
    map['source'] = Variable<String>(source);
    return map;
  }

  WordMaterialsCompanion toCompanion(bool nullToAbsent) {
    return WordMaterialsCompanion(
      wordId: Value(wordId),
      phoneticUk: Value(phoneticUk),
      phoneticUs: Value(phoneticUs),
      sensesJson: Value(sensesJson),
      phrasesJson: Value(phrasesJson),
      unclassifiedExamplesJson: Value(unclassifiedExamplesJson),
      rawHtml: Value(rawHtml),
      source: Value(source),
    );
  }

  factory WordMaterial.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WordMaterial(
      wordId: serializer.fromJson<int>(json['wordId']),
      phoneticUk: serializer.fromJson<String>(json['phoneticUk']),
      phoneticUs: serializer.fromJson<String>(json['phoneticUs']),
      sensesJson: serializer.fromJson<String>(json['sensesJson']),
      phrasesJson: serializer.fromJson<String>(json['phrasesJson']),
      unclassifiedExamplesJson: serializer.fromJson<String>(
        json['unclassifiedExamplesJson'],
      ),
      rawHtml: serializer.fromJson<String>(json['rawHtml']),
      source: serializer.fromJson<String>(json['source']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'wordId': serializer.toJson<int>(wordId),
      'phoneticUk': serializer.toJson<String>(phoneticUk),
      'phoneticUs': serializer.toJson<String>(phoneticUs),
      'sensesJson': serializer.toJson<String>(sensesJson),
      'phrasesJson': serializer.toJson<String>(phrasesJson),
      'unclassifiedExamplesJson': serializer.toJson<String>(
        unclassifiedExamplesJson,
      ),
      'rawHtml': serializer.toJson<String>(rawHtml),
      'source': serializer.toJson<String>(source),
    };
  }

  WordMaterial copyWith({
    int? wordId,
    String? phoneticUk,
    String? phoneticUs,
    String? sensesJson,
    String? phrasesJson,
    String? unclassifiedExamplesJson,
    String? rawHtml,
    String? source,
  }) => WordMaterial(
    wordId: wordId ?? this.wordId,
    phoneticUk: phoneticUk ?? this.phoneticUk,
    phoneticUs: phoneticUs ?? this.phoneticUs,
    sensesJson: sensesJson ?? this.sensesJson,
    phrasesJson: phrasesJson ?? this.phrasesJson,
    unclassifiedExamplesJson:
        unclassifiedExamplesJson ?? this.unclassifiedExamplesJson,
    rawHtml: rawHtml ?? this.rawHtml,
    source: source ?? this.source,
  );
  WordMaterial copyWithCompanion(WordMaterialsCompanion data) {
    return WordMaterial(
      wordId: data.wordId.present ? data.wordId.value : this.wordId,
      phoneticUk: data.phoneticUk.present
          ? data.phoneticUk.value
          : this.phoneticUk,
      phoneticUs: data.phoneticUs.present
          ? data.phoneticUs.value
          : this.phoneticUs,
      sensesJson: data.sensesJson.present
          ? data.sensesJson.value
          : this.sensesJson,
      phrasesJson: data.phrasesJson.present
          ? data.phrasesJson.value
          : this.phrasesJson,
      unclassifiedExamplesJson: data.unclassifiedExamplesJson.present
          ? data.unclassifiedExamplesJson.value
          : this.unclassifiedExamplesJson,
      rawHtml: data.rawHtml.present ? data.rawHtml.value : this.rawHtml,
      source: data.source.present ? data.source.value : this.source,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WordMaterial(')
          ..write('wordId: $wordId, ')
          ..write('phoneticUk: $phoneticUk, ')
          ..write('phoneticUs: $phoneticUs, ')
          ..write('sensesJson: $sensesJson, ')
          ..write('phrasesJson: $phrasesJson, ')
          ..write('unclassifiedExamplesJson: $unclassifiedExamplesJson, ')
          ..write('rawHtml: $rawHtml, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    wordId,
    phoneticUk,
    phoneticUs,
    sensesJson,
    phrasesJson,
    unclassifiedExamplesJson,
    rawHtml,
    source,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WordMaterial &&
          other.wordId == this.wordId &&
          other.phoneticUk == this.phoneticUk &&
          other.phoneticUs == this.phoneticUs &&
          other.sensesJson == this.sensesJson &&
          other.phrasesJson == this.phrasesJson &&
          other.unclassifiedExamplesJson == this.unclassifiedExamplesJson &&
          other.rawHtml == this.rawHtml &&
          other.source == this.source);
}

class WordMaterialsCompanion extends UpdateCompanion<WordMaterial> {
  final Value<int> wordId;
  final Value<String> phoneticUk;
  final Value<String> phoneticUs;
  final Value<String> sensesJson;
  final Value<String> phrasesJson;
  final Value<String> unclassifiedExamplesJson;
  final Value<String> rawHtml;
  final Value<String> source;
  const WordMaterialsCompanion({
    this.wordId = const Value.absent(),
    this.phoneticUk = const Value.absent(),
    this.phoneticUs = const Value.absent(),
    this.sensesJson = const Value.absent(),
    this.phrasesJson = const Value.absent(),
    this.unclassifiedExamplesJson = const Value.absent(),
    this.rawHtml = const Value.absent(),
    this.source = const Value.absent(),
  });
  WordMaterialsCompanion.insert({
    this.wordId = const Value.absent(),
    this.phoneticUk = const Value.absent(),
    this.phoneticUs = const Value.absent(),
    required String sensesJson,
    this.phrasesJson = const Value.absent(),
    this.unclassifiedExamplesJson = const Value.absent(),
    this.rawHtml = const Value.absent(),
    this.source = const Value.absent(),
  }) : sensesJson = Value(sensesJson);
  static Insertable<WordMaterial> custom({
    Expression<int>? wordId,
    Expression<String>? phoneticUk,
    Expression<String>? phoneticUs,
    Expression<String>? sensesJson,
    Expression<String>? phrasesJson,
    Expression<String>? unclassifiedExamplesJson,
    Expression<String>? rawHtml,
    Expression<String>? source,
  }) {
    return RawValuesInsertable({
      if (wordId != null) 'word_id': wordId,
      if (phoneticUk != null) 'phonetic_uk': phoneticUk,
      if (phoneticUs != null) 'phonetic_us': phoneticUs,
      if (sensesJson != null) 'senses_json': sensesJson,
      if (phrasesJson != null) 'phrases_json': phrasesJson,
      if (unclassifiedExamplesJson != null)
        'unclassified_examples_json': unclassifiedExamplesJson,
      if (rawHtml != null) 'raw_html': rawHtml,
      if (source != null) 'source': source,
    });
  }

  WordMaterialsCompanion copyWith({
    Value<int>? wordId,
    Value<String>? phoneticUk,
    Value<String>? phoneticUs,
    Value<String>? sensesJson,
    Value<String>? phrasesJson,
    Value<String>? unclassifiedExamplesJson,
    Value<String>? rawHtml,
    Value<String>? source,
  }) {
    return WordMaterialsCompanion(
      wordId: wordId ?? this.wordId,
      phoneticUk: phoneticUk ?? this.phoneticUk,
      phoneticUs: phoneticUs ?? this.phoneticUs,
      sensesJson: sensesJson ?? this.sensesJson,
      phrasesJson: phrasesJson ?? this.phrasesJson,
      unclassifiedExamplesJson:
          unclassifiedExamplesJson ?? this.unclassifiedExamplesJson,
      rawHtml: rawHtml ?? this.rawHtml,
      source: source ?? this.source,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (wordId.present) {
      map['word_id'] = Variable<int>(wordId.value);
    }
    if (phoneticUk.present) {
      map['phonetic_uk'] = Variable<String>(phoneticUk.value);
    }
    if (phoneticUs.present) {
      map['phonetic_us'] = Variable<String>(phoneticUs.value);
    }
    if (sensesJson.present) {
      map['senses_json'] = Variable<String>(sensesJson.value);
    }
    if (phrasesJson.present) {
      map['phrases_json'] = Variable<String>(phrasesJson.value);
    }
    if (unclassifiedExamplesJson.present) {
      map['unclassified_examples_json'] = Variable<String>(
        unclassifiedExamplesJson.value,
      );
    }
    if (rawHtml.present) {
      map['raw_html'] = Variable<String>(rawHtml.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordMaterialsCompanion(')
          ..write('wordId: $wordId, ')
          ..write('phoneticUk: $phoneticUk, ')
          ..write('phoneticUs: $phoneticUs, ')
          ..write('sensesJson: $sensesJson, ')
          ..write('phrasesJson: $phrasesJson, ')
          ..write('unclassifiedExamplesJson: $unclassifiedExamplesJson, ')
          ..write('rawHtml: $rawHtml, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }
}

class $AudioCachesTable extends AudioCaches
    with TableInfo<$AudioCachesTable, AudioCache> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AudioCachesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _wordIdMeta = const VerificationMeta('wordId');
  @override
  late final GeneratedColumn<int> wordId = GeneratedColumn<int>(
    'word_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES words (id)',
    ),
  );
  static const VerificationMeta _variantMeta = const VerificationMeta(
    'variant',
  );
  @override
  late final GeneratedColumn<String> variant = GeneratedColumn<String>(
    'variant',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _formatMeta = const VerificationMeta('format');
  @override
  late final GeneratedColumn<String> format = GeneratedColumn<String>(
    'format',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    wordId,
    variant,
    origin,
    path,
    format,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'audio_caches';
  @override
  VerificationContext validateIntegrity(
    Insertable<AudioCache> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('word_id')) {
      context.handle(
        _wordIdMeta,
        wordId.isAcceptableOrUnknown(data['word_id']!, _wordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_wordIdMeta);
    }
    if (data.containsKey('variant')) {
      context.handle(
        _variantMeta,
        variant.isAcceptableOrUnknown(data['variant']!, _variantMeta),
      );
    } else if (isInserting) {
      context.missing(_variantMeta);
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    } else if (isInserting) {
      context.missing(_originMeta);
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('format')) {
      context.handle(
        _formatMeta,
        format.isAcceptableOrUnknown(data['format']!, _formatMeta),
      );
    } else if (isInserting) {
      context.missing(_formatMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AudioCache map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AudioCache(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      wordId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}word_id'],
      )!,
      variant: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variant'],
      )!,
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      format: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}format'],
      )!,
    );
  }

  @override
  $AudioCachesTable createAlias(String alias) {
    return $AudioCachesTable(attachedDatabase, alias);
  }
}

class AudioCache extends DataClass implements Insertable<AudioCache> {
  final int id;
  final int wordId;
  final String variant;

  /// 音频来源:tts / mdd
  final String origin;
  final String path;
  final String format;
  const AudioCache({
    required this.id,
    required this.wordId,
    required this.variant,
    required this.origin,
    required this.path,
    required this.format,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['word_id'] = Variable<int>(wordId);
    map['variant'] = Variable<String>(variant);
    map['origin'] = Variable<String>(origin);
    map['path'] = Variable<String>(path);
    map['format'] = Variable<String>(format);
    return map;
  }

  AudioCachesCompanion toCompanion(bool nullToAbsent) {
    return AudioCachesCompanion(
      id: Value(id),
      wordId: Value(wordId),
      variant: Value(variant),
      origin: Value(origin),
      path: Value(path),
      format: Value(format),
    );
  }

  factory AudioCache.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AudioCache(
      id: serializer.fromJson<int>(json['id']),
      wordId: serializer.fromJson<int>(json['wordId']),
      variant: serializer.fromJson<String>(json['variant']),
      origin: serializer.fromJson<String>(json['origin']),
      path: serializer.fromJson<String>(json['path']),
      format: serializer.fromJson<String>(json['format']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'wordId': serializer.toJson<int>(wordId),
      'variant': serializer.toJson<String>(variant),
      'origin': serializer.toJson<String>(origin),
      'path': serializer.toJson<String>(path),
      'format': serializer.toJson<String>(format),
    };
  }

  AudioCache copyWith({
    int? id,
    int? wordId,
    String? variant,
    String? origin,
    String? path,
    String? format,
  }) => AudioCache(
    id: id ?? this.id,
    wordId: wordId ?? this.wordId,
    variant: variant ?? this.variant,
    origin: origin ?? this.origin,
    path: path ?? this.path,
    format: format ?? this.format,
  );
  AudioCache copyWithCompanion(AudioCachesCompanion data) {
    return AudioCache(
      id: data.id.present ? data.id.value : this.id,
      wordId: data.wordId.present ? data.wordId.value : this.wordId,
      variant: data.variant.present ? data.variant.value : this.variant,
      origin: data.origin.present ? data.origin.value : this.origin,
      path: data.path.present ? data.path.value : this.path,
      format: data.format.present ? data.format.value : this.format,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AudioCache(')
          ..write('id: $id, ')
          ..write('wordId: $wordId, ')
          ..write('variant: $variant, ')
          ..write('origin: $origin, ')
          ..write('path: $path, ')
          ..write('format: $format')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, wordId, variant, origin, path, format);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AudioCache &&
          other.id == this.id &&
          other.wordId == this.wordId &&
          other.variant == this.variant &&
          other.origin == this.origin &&
          other.path == this.path &&
          other.format == this.format);
}

class AudioCachesCompanion extends UpdateCompanion<AudioCache> {
  final Value<int> id;
  final Value<int> wordId;
  final Value<String> variant;
  final Value<String> origin;
  final Value<String> path;
  final Value<String> format;
  const AudioCachesCompanion({
    this.id = const Value.absent(),
    this.wordId = const Value.absent(),
    this.variant = const Value.absent(),
    this.origin = const Value.absent(),
    this.path = const Value.absent(),
    this.format = const Value.absent(),
  });
  AudioCachesCompanion.insert({
    this.id = const Value.absent(),
    required int wordId,
    required String variant,
    required String origin,
    required String path,
    required String format,
  }) : wordId = Value(wordId),
       variant = Value(variant),
       origin = Value(origin),
       path = Value(path),
       format = Value(format);
  static Insertable<AudioCache> custom({
    Expression<int>? id,
    Expression<int>? wordId,
    Expression<String>? variant,
    Expression<String>? origin,
    Expression<String>? path,
    Expression<String>? format,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (wordId != null) 'word_id': wordId,
      if (variant != null) 'variant': variant,
      if (origin != null) 'origin': origin,
      if (path != null) 'path': path,
      if (format != null) 'format': format,
    });
  }

  AudioCachesCompanion copyWith({
    Value<int>? id,
    Value<int>? wordId,
    Value<String>? variant,
    Value<String>? origin,
    Value<String>? path,
    Value<String>? format,
  }) {
    return AudioCachesCompanion(
      id: id ?? this.id,
      wordId: wordId ?? this.wordId,
      variant: variant ?? this.variant,
      origin: origin ?? this.origin,
      path: path ?? this.path,
      format: format ?? this.format,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (wordId.present) {
      map['word_id'] = Variable<int>(wordId.value);
    }
    if (variant.present) {
      map['variant'] = Variable<String>(variant.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (format.present) {
      map['format'] = Variable<String>(format.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AudioCachesCompanion(')
          ..write('id: $id, ')
          ..write('wordId: $wordId, ')
          ..write('variant: $variant, ')
          ..write('origin: $origin, ')
          ..write('path: $path, ')
          ..write('format: $format')
          ..write(')'))
        .toString();
  }
}

class $ReviewStatesTableTable extends ReviewStatesTable
    with TableInfo<$ReviewStatesTableTable, ReviewState> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReviewStatesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _wordIdMeta = const VerificationMeta('wordId');
  @override
  late final GeneratedColumn<int> wordId = GeneratedColumn<int>(
    'word_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES words (id)',
    ),
  );
  static const VerificationMeta _knownMeta = const VerificationMeta('known');
  @override
  late final GeneratedColumn<bool> known = GeneratedColumn<bool>(
    'known',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("known" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _intervalMeta = const VerificationMeta(
    'interval',
  );
  @override
  late final GeneratedColumn<int> interval = GeneratedColumn<int>(
    'interval',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nextReviewAtMeta = const VerificationMeta(
    'nextReviewAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextReviewAt = GeneratedColumn<DateTime>(
    'next_review_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deviceSeqMeta = const VerificationMeta(
    'deviceSeq',
  );
  @override
  late final GeneratedColumn<int> deviceSeq = GeneratedColumn<int>(
    'device_seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    wordId,
    known,
    interval,
    nextReviewAt,
    updatedAt,
    deviceSeq,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'review_states_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReviewState> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('word_id')) {
      context.handle(
        _wordIdMeta,
        wordId.isAcceptableOrUnknown(data['word_id']!, _wordIdMeta),
      );
    }
    if (data.containsKey('known')) {
      context.handle(
        _knownMeta,
        known.isAcceptableOrUnknown(data['known']!, _knownMeta),
      );
    }
    if (data.containsKey('interval')) {
      context.handle(
        _intervalMeta,
        interval.isAcceptableOrUnknown(data['interval']!, _intervalMeta),
      );
    }
    if (data.containsKey('next_review_at')) {
      context.handle(
        _nextReviewAtMeta,
        nextReviewAt.isAcceptableOrUnknown(
          data['next_review_at']!,
          _nextReviewAtMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('device_seq')) {
      context.handle(
        _deviceSeqMeta,
        deviceSeq.isAcceptableOrUnknown(data['device_seq']!, _deviceSeqMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {wordId};
  @override
  ReviewState map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReviewState(
      wordId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}word_id'],
      )!,
      known: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}known'],
      )!,
      interval: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval'],
      )!,
      nextReviewAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_review_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deviceSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}device_seq'],
      )!,
    );
  }

  @override
  $ReviewStatesTableTable createAlias(String alias) {
    return $ReviewStatesTableTable(attachedDatabase, alias);
  }
}

class ReviewState extends DataClass implements Insertable<ReviewState> {
  final int wordId;
  final bool known;

  /// 间隔天数:1/3/7
  final int interval;
  final DateTime? nextReviewAt;
  final DateTime updatedAt;

  /// 设备逻辑序号,用于 LWW 冲突解决(§9.1)
  final int deviceSeq;
  const ReviewState({
    required this.wordId,
    required this.known,
    required this.interval,
    this.nextReviewAt,
    required this.updatedAt,
    required this.deviceSeq,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['word_id'] = Variable<int>(wordId);
    map['known'] = Variable<bool>(known);
    map['interval'] = Variable<int>(interval);
    if (!nullToAbsent || nextReviewAt != null) {
      map['next_review_at'] = Variable<DateTime>(nextReviewAt);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['device_seq'] = Variable<int>(deviceSeq);
    return map;
  }

  ReviewStatesTableCompanion toCompanion(bool nullToAbsent) {
    return ReviewStatesTableCompanion(
      wordId: Value(wordId),
      known: Value(known),
      interval: Value(interval),
      nextReviewAt: nextReviewAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextReviewAt),
      updatedAt: Value(updatedAt),
      deviceSeq: Value(deviceSeq),
    );
  }

  factory ReviewState.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReviewState(
      wordId: serializer.fromJson<int>(json['wordId']),
      known: serializer.fromJson<bool>(json['known']),
      interval: serializer.fromJson<int>(json['interval']),
      nextReviewAt: serializer.fromJson<DateTime?>(json['nextReviewAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deviceSeq: serializer.fromJson<int>(json['deviceSeq']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'wordId': serializer.toJson<int>(wordId),
      'known': serializer.toJson<bool>(known),
      'interval': serializer.toJson<int>(interval),
      'nextReviewAt': serializer.toJson<DateTime?>(nextReviewAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deviceSeq': serializer.toJson<int>(deviceSeq),
    };
  }

  ReviewState copyWith({
    int? wordId,
    bool? known,
    int? interval,
    Value<DateTime?> nextReviewAt = const Value.absent(),
    DateTime? updatedAt,
    int? deviceSeq,
  }) => ReviewState(
    wordId: wordId ?? this.wordId,
    known: known ?? this.known,
    interval: interval ?? this.interval,
    nextReviewAt: nextReviewAt.present ? nextReviewAt.value : this.nextReviewAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deviceSeq: deviceSeq ?? this.deviceSeq,
  );
  ReviewState copyWithCompanion(ReviewStatesTableCompanion data) {
    return ReviewState(
      wordId: data.wordId.present ? data.wordId.value : this.wordId,
      known: data.known.present ? data.known.value : this.known,
      interval: data.interval.present ? data.interval.value : this.interval,
      nextReviewAt: data.nextReviewAt.present
          ? data.nextReviewAt.value
          : this.nextReviewAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deviceSeq: data.deviceSeq.present ? data.deviceSeq.value : this.deviceSeq,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReviewState(')
          ..write('wordId: $wordId, ')
          ..write('known: $known, ')
          ..write('interval: $interval, ')
          ..write('nextReviewAt: $nextReviewAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deviceSeq: $deviceSeq')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(wordId, known, interval, nextReviewAt, updatedAt, deviceSeq);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReviewState &&
          other.wordId == this.wordId &&
          other.known == this.known &&
          other.interval == this.interval &&
          other.nextReviewAt == this.nextReviewAt &&
          other.updatedAt == this.updatedAt &&
          other.deviceSeq == this.deviceSeq);
}

class ReviewStatesTableCompanion extends UpdateCompanion<ReviewState> {
  final Value<int> wordId;
  final Value<bool> known;
  final Value<int> interval;
  final Value<DateTime?> nextReviewAt;
  final Value<DateTime> updatedAt;
  final Value<int> deviceSeq;
  const ReviewStatesTableCompanion({
    this.wordId = const Value.absent(),
    this.known = const Value.absent(),
    this.interval = const Value.absent(),
    this.nextReviewAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deviceSeq = const Value.absent(),
  });
  ReviewStatesTableCompanion.insert({
    this.wordId = const Value.absent(),
    this.known = const Value.absent(),
    this.interval = const Value.absent(),
    this.nextReviewAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deviceSeq = const Value.absent(),
  });
  static Insertable<ReviewState> custom({
    Expression<int>? wordId,
    Expression<bool>? known,
    Expression<int>? interval,
    Expression<DateTime>? nextReviewAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? deviceSeq,
  }) {
    return RawValuesInsertable({
      if (wordId != null) 'word_id': wordId,
      if (known != null) 'known': known,
      if (interval != null) 'interval': interval,
      if (nextReviewAt != null) 'next_review_at': nextReviewAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deviceSeq != null) 'device_seq': deviceSeq,
    });
  }

  ReviewStatesTableCompanion copyWith({
    Value<int>? wordId,
    Value<bool>? known,
    Value<int>? interval,
    Value<DateTime?>? nextReviewAt,
    Value<DateTime>? updatedAt,
    Value<int>? deviceSeq,
  }) {
    return ReviewStatesTableCompanion(
      wordId: wordId ?? this.wordId,
      known: known ?? this.known,
      interval: interval ?? this.interval,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deviceSeq: deviceSeq ?? this.deviceSeq,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (wordId.present) {
      map['word_id'] = Variable<int>(wordId.value);
    }
    if (known.present) {
      map['known'] = Variable<bool>(known.value);
    }
    if (interval.present) {
      map['interval'] = Variable<int>(interval.value);
    }
    if (nextReviewAt.present) {
      map['next_review_at'] = Variable<DateTime>(nextReviewAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deviceSeq.present) {
      map['device_seq'] = Variable<int>(deviceSeq.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReviewStatesTableCompanion(')
          ..write('wordId: $wordId, ')
          ..write('known: $known, ')
          ..write('interval: $interval, ')
          ..write('nextReviewAt: $nextReviewAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deviceSeq: $deviceSeq')
          ..write(')'))
        .toString();
  }
}

class $PendingQueuesTable extends PendingQueues
    with TableInfo<$PendingQueuesTable, PendingQueue> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingQueuesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  @override
  List<GeneratedColumn> get $columns => [id, kind, payload, state];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_queues';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingQueue> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingQueue map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingQueue(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
    );
  }

  @override
  $PendingQueuesTable createAlias(String alias) {
    return $PendingQueuesTable(attachedDatabase, alias);
  }
}

class PendingQueue extends DataClass implements Insertable<PendingQueue> {
  final int id;
  final String kind;
  final String payload;
  final String state;
  const PendingQueue({
    required this.id,
    required this.kind,
    required this.payload,
    required this.state,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['kind'] = Variable<String>(kind);
    map['payload'] = Variable<String>(payload);
    map['state'] = Variable<String>(state);
    return map;
  }

  PendingQueuesCompanion toCompanion(bool nullToAbsent) {
    return PendingQueuesCompanion(
      id: Value(id),
      kind: Value(kind),
      payload: Value(payload),
      state: Value(state),
    );
  }

  factory PendingQueue.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingQueue(
      id: serializer.fromJson<int>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      payload: serializer.fromJson<String>(json['payload']),
      state: serializer.fromJson<String>(json['state']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'kind': serializer.toJson<String>(kind),
      'payload': serializer.toJson<String>(payload),
      'state': serializer.toJson<String>(state),
    };
  }

  PendingQueue copyWith({
    int? id,
    String? kind,
    String? payload,
    String? state,
  }) => PendingQueue(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    payload: payload ?? this.payload,
    state: state ?? this.state,
  );
  PendingQueue copyWithCompanion(PendingQueuesCompanion data) {
    return PendingQueue(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      payload: data.payload.present ? data.payload.value : this.payload,
      state: data.state.present ? data.state.value : this.state,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingQueue(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('payload: $payload, ')
          ..write('state: $state')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, kind, payload, state);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingQueue &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.payload == this.payload &&
          other.state == this.state);
}

class PendingQueuesCompanion extends UpdateCompanion<PendingQueue> {
  final Value<int> id;
  final Value<String> kind;
  final Value<String> payload;
  final Value<String> state;
  const PendingQueuesCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.payload = const Value.absent(),
    this.state = const Value.absent(),
  });
  PendingQueuesCompanion.insert({
    this.id = const Value.absent(),
    required String kind,
    required String payload,
    this.state = const Value.absent(),
  }) : kind = Value(kind),
       payload = Value(payload);
  static Insertable<PendingQueue> custom({
    Expression<int>? id,
    Expression<String>? kind,
    Expression<String>? payload,
    Expression<String>? state,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (payload != null) 'payload': payload,
      if (state != null) 'state': state,
    });
  }

  PendingQueuesCompanion copyWith({
    Value<int>? id,
    Value<String>? kind,
    Value<String>? payload,
    Value<String>? state,
  }) {
    return PendingQueuesCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      payload: payload ?? this.payload,
      state: state ?? this.state,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingQueuesCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('payload: $payload, ')
          ..write('state: $state')
          ..write(')'))
        .toString();
  }
}

class $SettingsTableTable extends SettingsTable
    with TableInfo<$SettingsTableTable, SettingsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingsTableData(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingsTableTable createAlias(String alias) {
    return $SettingsTableTable(attachedDatabase, alias);
  }
}

class SettingsTableData extends DataClass
    implements Insertable<SettingsTableData> {
  final String key;
  final String value;
  const SettingsTableData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsTableCompanion toCompanion(bool nullToAbsent) {
    return SettingsTableCompanion(key: Value(key), value: Value(value));
  }

  factory SettingsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingsTableData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SettingsTableData copyWith({String? key, String? value}) =>
      SettingsTableData(key: key ?? this.key, value: value ?? this.value);
  SettingsTableData copyWithCompanion(SettingsTableCompanion data) {
    return SettingsTableData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingsTableData(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingsTableData &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingsTableCompanion extends UpdateCompanion<SettingsTableData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsTableCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsTableCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SettingsTableData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsTableCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsTableCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsTableCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BudgetDaysTable extends BudgetDays
    with TableInfo<$BudgetDaysTable, BudgetDay> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BudgetDaysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _countMeta = const VerificationMeta('count');
  @override
  late final GeneratedColumn<int> count = GeneratedColumn<int>(
    'count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [day, count];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'budget_days';
  @override
  VerificationContext validateIntegrity(
    Insertable<BudgetDay> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('count')) {
      context.handle(
        _countMeta,
        count.isAcceptableOrUnknown(data['count']!, _countMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {day};
  @override
  BudgetDay map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BudgetDay(
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      count: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}count'],
      )!,
    );
  }

  @override
  $BudgetDaysTable createAlias(String alias) {
    return $BudgetDaysTable(attachedDatabase, alias);
  }
}

class BudgetDay extends DataClass implements Insertable<BudgetDay> {
  /// 自然日,格式 'yyyy-MM-dd'(本地时区)
  final String day;
  final int count;
  const BudgetDay({required this.day, required this.count});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['day'] = Variable<String>(day);
    map['count'] = Variable<int>(count);
    return map;
  }

  BudgetDaysCompanion toCompanion(bool nullToAbsent) {
    return BudgetDaysCompanion(day: Value(day), count: Value(count));
  }

  factory BudgetDay.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BudgetDay(
      day: serializer.fromJson<String>(json['day']),
      count: serializer.fromJson<int>(json['count']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'day': serializer.toJson<String>(day),
      'count': serializer.toJson<int>(count),
    };
  }

  BudgetDay copyWith({String? day, int? count}) =>
      BudgetDay(day: day ?? this.day, count: count ?? this.count);
  BudgetDay copyWithCompanion(BudgetDaysCompanion data) {
    return BudgetDay(
      day: data.day.present ? data.day.value : this.day,
      count: data.count.present ? data.count.value : this.count,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BudgetDay(')
          ..write('day: $day, ')
          ..write('count: $count')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(day, count);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BudgetDay &&
          other.day == this.day &&
          other.count == this.count);
}

class BudgetDaysCompanion extends UpdateCompanion<BudgetDay> {
  final Value<String> day;
  final Value<int> count;
  final Value<int> rowid;
  const BudgetDaysCompanion({
    this.day = const Value.absent(),
    this.count = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BudgetDaysCompanion.insert({
    required String day,
    this.count = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : day = Value(day);
  static Insertable<BudgetDay> custom({
    Expression<String>? day,
    Expression<int>? count,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (day != null) 'day': day,
      if (count != null) 'count': count,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BudgetDaysCompanion copyWith({
    Value<String>? day,
    Value<int>? count,
    Value<int>? rowid,
  }) {
    return BudgetDaysCompanion(
      day: day ?? this.day,
      count: count ?? this.count,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (count.present) {
      map['count'] = Variable<int>(count.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BudgetDaysCompanion(')
          ..write('day: $day, ')
          ..write('count: $count, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $WordSetsTable wordSets = $WordSetsTable(this);
  late final $WordsTable words = $WordsTable(this);
  late final $WordMaterialsTable wordMaterials = $WordMaterialsTable(this);
  late final $AudioCachesTable audioCaches = $AudioCachesTable(this);
  late final $ReviewStatesTableTable reviewStatesTable =
      $ReviewStatesTableTable(this);
  late final $PendingQueuesTable pendingQueues = $PendingQueuesTable(this);
  late final $SettingsTableTable settingsTable = $SettingsTableTable(this);
  late final $BudgetDaysTable budgetDays = $BudgetDaysTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    wordSets,
    words,
    wordMaterials,
    audioCaches,
    reviewStatesTable,
    pendingQueues,
    settingsTable,
    budgetDays,
  ];
}

typedef $$WordSetsTableCreateCompanionBuilder =
    WordSetsCompanion Function({
      Value<int> id,
      required String name,
      Value<DateTime> createdAt,
    });
typedef $$WordSetsTableUpdateCompanionBuilder =
    WordSetsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<DateTime> createdAt,
    });

final class $$WordSetsTableReferences
    extends BaseReferences<_$AppDatabase, $WordSetsTable, WordSet> {
  $$WordSetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$WordsTable, List<Word>> _wordsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.words,
    aliasName: 'word_sets__id__words__word_set_id',
  );

  $$WordsTableProcessedTableManager get wordsRefs {
    final manager = $$WordsTableTableManager(
      $_db,
      $_db.words,
    ).filter((f) => f.wordSetId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_wordsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WordSetsTableFilterComposer
    extends Composer<_$AppDatabase, $WordSetsTable> {
  $$WordSetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> wordsRefs(
    Expression<bool> Function($$WordsTableFilterComposer f) f,
  ) {
    final $$WordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.wordSetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableFilterComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WordSetsTableOrderingComposer
    extends Composer<_$AppDatabase, $WordSetsTable> {
  $$WordSetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WordSetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WordSetsTable> {
  $$WordSetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> wordsRefs<T extends Object>(
    Expression<T> Function($$WordsTableAnnotationComposer a) f,
  ) {
    final $$WordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.wordSetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableAnnotationComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WordSetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WordSetsTable,
          WordSet,
          $$WordSetsTableFilterComposer,
          $$WordSetsTableOrderingComposer,
          $$WordSetsTableAnnotationComposer,
          $$WordSetsTableCreateCompanionBuilder,
          $$WordSetsTableUpdateCompanionBuilder,
          (WordSet, $$WordSetsTableReferences),
          WordSet,
          PrefetchHooks Function({bool wordsRefs})
        > {
  $$WordSetsTableTableManager(_$AppDatabase db, $WordSetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WordSetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WordSetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WordSetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => WordSetsCompanion(id: id, name: name, createdAt: createdAt),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<DateTime> createdAt = const Value.absent(),
              }) => WordSetsCompanion.insert(
                id: id,
                name: name,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$WordSetsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({wordsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (wordsRefs) db.words],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (wordsRefs)
                    await $_getPrefetchedData<WordSet, $WordSetsTable, Word>(
                      currentTable: table,
                      referencedTable: $$WordSetsTableReferences
                          ._wordsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$WordSetsTableReferences(db, table, p0).wordsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.wordSetId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$WordSetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WordSetsTable,
      WordSet,
      $$WordSetsTableFilterComposer,
      $$WordSetsTableOrderingComposer,
      $$WordSetsTableAnnotationComposer,
      $$WordSetsTableCreateCompanionBuilder,
      $$WordSetsTableUpdateCompanionBuilder,
      (WordSet, $$WordSetsTableReferences),
      WordSet,
      PrefetchHooks Function({bool wordsRefs})
    >;
typedef $$WordsTableCreateCompanionBuilder =
    WordsCompanion Function({
      Value<int> id,
      required int wordSetId,
      required String headword,
      Value<String> source,
      Value<String> sourceName,
      Value<String> status,
      Value<int> sortKey,
    });
typedef $$WordsTableUpdateCompanionBuilder =
    WordsCompanion Function({
      Value<int> id,
      Value<int> wordSetId,
      Value<String> headword,
      Value<String> source,
      Value<String> sourceName,
      Value<String> status,
      Value<int> sortKey,
    });

final class $$WordsTableReferences
    extends BaseReferences<_$AppDatabase, $WordsTable, Word> {
  $$WordsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WordSetsTable _wordSetIdTable(_$AppDatabase db) =>
      db.wordSets.createAlias('words__word_set_id__word_sets__id');

  $$WordSetsTableProcessedTableManager get wordSetId {
    final $_column = $_itemColumn<int>('word_set_id')!;

    final manager = $$WordSetsTableTableManager(
      $_db,
      $_db.wordSets,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_wordSetIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$WordMaterialsTable, List<WordMaterial>>
  _wordMaterialsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.wordMaterials,
    aliasName: 'words__id__word_materials__word_id',
  );

  $$WordMaterialsTableProcessedTableManager get wordMaterialsRefs {
    final manager = $$WordMaterialsTableTableManager(
      $_db,
      $_db.wordMaterials,
    ).filter((f) => f.wordId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_wordMaterialsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AudioCachesTable, List<AudioCache>>
  _audioCachesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.audioCaches,
    aliasName: 'words__id__audio_caches__word_id',
  );

  $$AudioCachesTableProcessedTableManager get audioCachesRefs {
    final manager = $$AudioCachesTableTableManager(
      $_db,
      $_db.audioCaches,
    ).filter((f) => f.wordId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_audioCachesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ReviewStatesTableTable, List<ReviewState>>
  _reviewStatesTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.reviewStatesTable,
        aliasName: 'words__id__review_states_table__word_id',
      );

  $$ReviewStatesTableTableProcessedTableManager get reviewStatesTableRefs {
    final manager = $$ReviewStatesTableTableTableManager(
      $_db,
      $_db.reviewStatesTable,
    ).filter((f) => f.wordId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _reviewStatesTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WordsTableFilterComposer extends Composer<_$AppDatabase, $WordsTable> {
  $$WordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get headword => $composableBuilder(
    column: $table.headword,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceName => $composableBuilder(
    column: $table.sourceName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortKey => $composableBuilder(
    column: $table.sortKey,
    builder: (column) => ColumnFilters(column),
  );

  $$WordSetsTableFilterComposer get wordSetId {
    final $$WordSetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordSetId,
      referencedTable: $db.wordSets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordSetsTableFilterComposer(
            $db: $db,
            $table: $db.wordSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> wordMaterialsRefs(
    Expression<bool> Function($$WordMaterialsTableFilterComposer f) f,
  ) {
    final $$WordMaterialsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.wordMaterials,
      getReferencedColumn: (t) => t.wordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordMaterialsTableFilterComposer(
            $db: $db,
            $table: $db.wordMaterials,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> audioCachesRefs(
    Expression<bool> Function($$AudioCachesTableFilterComposer f) f,
  ) {
    final $$AudioCachesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.audioCaches,
      getReferencedColumn: (t) => t.wordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AudioCachesTableFilterComposer(
            $db: $db,
            $table: $db.audioCaches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> reviewStatesTableRefs(
    Expression<bool> Function($$ReviewStatesTableTableFilterComposer f) f,
  ) {
    final $$ReviewStatesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reviewStatesTable,
      getReferencedColumn: (t) => t.wordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReviewStatesTableTableFilterComposer(
            $db: $db,
            $table: $db.reviewStatesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WordsTableOrderingComposer
    extends Composer<_$AppDatabase, $WordsTable> {
  $$WordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get headword => $composableBuilder(
    column: $table.headword,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceName => $composableBuilder(
    column: $table.sourceName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortKey => $composableBuilder(
    column: $table.sortKey,
    builder: (column) => ColumnOrderings(column),
  );

  $$WordSetsTableOrderingComposer get wordSetId {
    final $$WordSetsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordSetId,
      referencedTable: $db.wordSets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordSetsTableOrderingComposer(
            $db: $db,
            $table: $db.wordSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WordsTable> {
  $$WordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get headword =>
      $composableBuilder(column: $table.headword, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get sourceName => $composableBuilder(
    column: $table.sourceName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get sortKey =>
      $composableBuilder(column: $table.sortKey, builder: (column) => column);

  $$WordSetsTableAnnotationComposer get wordSetId {
    final $$WordSetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordSetId,
      referencedTable: $db.wordSets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordSetsTableAnnotationComposer(
            $db: $db,
            $table: $db.wordSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> wordMaterialsRefs<T extends Object>(
    Expression<T> Function($$WordMaterialsTableAnnotationComposer a) f,
  ) {
    final $$WordMaterialsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.wordMaterials,
      getReferencedColumn: (t) => t.wordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordMaterialsTableAnnotationComposer(
            $db: $db,
            $table: $db.wordMaterials,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> audioCachesRefs<T extends Object>(
    Expression<T> Function($$AudioCachesTableAnnotationComposer a) f,
  ) {
    final $$AudioCachesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.audioCaches,
      getReferencedColumn: (t) => t.wordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AudioCachesTableAnnotationComposer(
            $db: $db,
            $table: $db.audioCaches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> reviewStatesTableRefs<T extends Object>(
    Expression<T> Function($$ReviewStatesTableTableAnnotationComposer a) f,
  ) {
    final $$ReviewStatesTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.reviewStatesTable,
          getReferencedColumn: (t) => t.wordId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ReviewStatesTableTableAnnotationComposer(
                $db: $db,
                $table: $db.reviewStatesTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$WordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WordsTable,
          Word,
          $$WordsTableFilterComposer,
          $$WordsTableOrderingComposer,
          $$WordsTableAnnotationComposer,
          $$WordsTableCreateCompanionBuilder,
          $$WordsTableUpdateCompanionBuilder,
          (Word, $$WordsTableReferences),
          Word,
          PrefetchHooks Function({
            bool wordSetId,
            bool wordMaterialsRefs,
            bool audioCachesRefs,
            bool reviewStatesTableRefs,
          })
        > {
  $$WordsTableTableManager(_$AppDatabase db, $WordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> wordSetId = const Value.absent(),
                Value<String> headword = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> sourceName = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> sortKey = const Value.absent(),
              }) => WordsCompanion(
                id: id,
                wordSetId: wordSetId,
                headword: headword,
                source: source,
                sourceName: sourceName,
                status: status,
                sortKey: sortKey,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int wordSetId,
                required String headword,
                Value<String> source = const Value.absent(),
                Value<String> sourceName = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> sortKey = const Value.absent(),
              }) => WordsCompanion.insert(
                id: id,
                wordSetId: wordSetId,
                headword: headword,
                source: source,
                sourceName: sourceName,
                status: status,
                sortKey: sortKey,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$WordsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                wordSetId = false,
                wordMaterialsRefs = false,
                audioCachesRefs = false,
                reviewStatesTableRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (wordMaterialsRefs) db.wordMaterials,
                    if (audioCachesRefs) db.audioCaches,
                    if (reviewStatesTableRefs) db.reviewStatesTable,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (wordSetId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.wordSetId,
                                    referencedTable: $$WordsTableReferences
                                        ._wordSetIdTable(db),
                                    referencedColumn: $$WordsTableReferences
                                        ._wordSetIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (wordMaterialsRefs)
                        await $_getPrefetchedData<
                          Word,
                          $WordsTable,
                          WordMaterial
                        >(
                          currentTable: table,
                          referencedTable: $$WordsTableReferences
                              ._wordMaterialsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WordsTableReferences(
                                db,
                                table,
                                p0,
                              ).wordMaterialsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.wordId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (audioCachesRefs)
                        await $_getPrefetchedData<
                          Word,
                          $WordsTable,
                          AudioCache
                        >(
                          currentTable: table,
                          referencedTable: $$WordsTableReferences
                              ._audioCachesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WordsTableReferences(
                                db,
                                table,
                                p0,
                              ).audioCachesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.wordId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (reviewStatesTableRefs)
                        await $_getPrefetchedData<
                          Word,
                          $WordsTable,
                          ReviewState
                        >(
                          currentTable: table,
                          referencedTable: $$WordsTableReferences
                              ._reviewStatesTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WordsTableReferences(
                                db,
                                table,
                                p0,
                              ).reviewStatesTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.wordId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$WordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WordsTable,
      Word,
      $$WordsTableFilterComposer,
      $$WordsTableOrderingComposer,
      $$WordsTableAnnotationComposer,
      $$WordsTableCreateCompanionBuilder,
      $$WordsTableUpdateCompanionBuilder,
      (Word, $$WordsTableReferences),
      Word,
      PrefetchHooks Function({
        bool wordSetId,
        bool wordMaterialsRefs,
        bool audioCachesRefs,
        bool reviewStatesTableRefs,
      })
    >;
typedef $$WordMaterialsTableCreateCompanionBuilder =
    WordMaterialsCompanion Function({
      Value<int> wordId,
      Value<String> phoneticUk,
      Value<String> phoneticUs,
      required String sensesJson,
      Value<String> phrasesJson,
      Value<String> unclassifiedExamplesJson,
      Value<String> rawHtml,
      Value<String> source,
    });
typedef $$WordMaterialsTableUpdateCompanionBuilder =
    WordMaterialsCompanion Function({
      Value<int> wordId,
      Value<String> phoneticUk,
      Value<String> phoneticUs,
      Value<String> sensesJson,
      Value<String> phrasesJson,
      Value<String> unclassifiedExamplesJson,
      Value<String> rawHtml,
      Value<String> source,
    });

final class $$WordMaterialsTableReferences
    extends BaseReferences<_$AppDatabase, $WordMaterialsTable, WordMaterial> {
  $$WordMaterialsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $WordsTable _wordIdTable(_$AppDatabase db) =>
      db.words.createAlias('word_materials__word_id__words__id');

  $$WordsTableProcessedTableManager get wordId {
    final $_column = $_itemColumn<int>('word_id')!;

    final manager = $$WordsTableTableManager(
      $_db,
      $_db.words,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_wordIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$WordMaterialsTableFilterComposer
    extends Composer<_$AppDatabase, $WordMaterialsTable> {
  $$WordMaterialsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get phoneticUk => $composableBuilder(
    column: $table.phoneticUk,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phoneticUs => $composableBuilder(
    column: $table.phoneticUs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sensesJson => $composableBuilder(
    column: $table.sensesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phrasesJson => $composableBuilder(
    column: $table.phrasesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unclassifiedExamplesJson => $composableBuilder(
    column: $table.unclassifiedExamplesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawHtml => $composableBuilder(
    column: $table.rawHtml,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  $$WordsTableFilterComposer get wordId {
    final $$WordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableFilterComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WordMaterialsTableOrderingComposer
    extends Composer<_$AppDatabase, $WordMaterialsTable> {
  $$WordMaterialsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get phoneticUk => $composableBuilder(
    column: $table.phoneticUk,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phoneticUs => $composableBuilder(
    column: $table.phoneticUs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sensesJson => $composableBuilder(
    column: $table.sensesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phrasesJson => $composableBuilder(
    column: $table.phrasesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unclassifiedExamplesJson => $composableBuilder(
    column: $table.unclassifiedExamplesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawHtml => $composableBuilder(
    column: $table.rawHtml,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  $$WordsTableOrderingComposer get wordId {
    final $$WordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableOrderingComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WordMaterialsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WordMaterialsTable> {
  $$WordMaterialsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get phoneticUk => $composableBuilder(
    column: $table.phoneticUk,
    builder: (column) => column,
  );

  GeneratedColumn<String> get phoneticUs => $composableBuilder(
    column: $table.phoneticUs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sensesJson => $composableBuilder(
    column: $table.sensesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get phrasesJson => $composableBuilder(
    column: $table.phrasesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get unclassifiedExamplesJson => $composableBuilder(
    column: $table.unclassifiedExamplesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rawHtml =>
      $composableBuilder(column: $table.rawHtml, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  $$WordsTableAnnotationComposer get wordId {
    final $$WordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableAnnotationComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WordMaterialsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WordMaterialsTable,
          WordMaterial,
          $$WordMaterialsTableFilterComposer,
          $$WordMaterialsTableOrderingComposer,
          $$WordMaterialsTableAnnotationComposer,
          $$WordMaterialsTableCreateCompanionBuilder,
          $$WordMaterialsTableUpdateCompanionBuilder,
          (WordMaterial, $$WordMaterialsTableReferences),
          WordMaterial,
          PrefetchHooks Function({bool wordId})
        > {
  $$WordMaterialsTableTableManager(_$AppDatabase db, $WordMaterialsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WordMaterialsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WordMaterialsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WordMaterialsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> wordId = const Value.absent(),
                Value<String> phoneticUk = const Value.absent(),
                Value<String> phoneticUs = const Value.absent(),
                Value<String> sensesJson = const Value.absent(),
                Value<String> phrasesJson = const Value.absent(),
                Value<String> unclassifiedExamplesJson = const Value.absent(),
                Value<String> rawHtml = const Value.absent(),
                Value<String> source = const Value.absent(),
              }) => WordMaterialsCompanion(
                wordId: wordId,
                phoneticUk: phoneticUk,
                phoneticUs: phoneticUs,
                sensesJson: sensesJson,
                phrasesJson: phrasesJson,
                unclassifiedExamplesJson: unclassifiedExamplesJson,
                rawHtml: rawHtml,
                source: source,
              ),
          createCompanionCallback:
              ({
                Value<int> wordId = const Value.absent(),
                Value<String> phoneticUk = const Value.absent(),
                Value<String> phoneticUs = const Value.absent(),
                required String sensesJson,
                Value<String> phrasesJson = const Value.absent(),
                Value<String> unclassifiedExamplesJson = const Value.absent(),
                Value<String> rawHtml = const Value.absent(),
                Value<String> source = const Value.absent(),
              }) => WordMaterialsCompanion.insert(
                wordId: wordId,
                phoneticUk: phoneticUk,
                phoneticUs: phoneticUs,
                sensesJson: sensesJson,
                phrasesJson: phrasesJson,
                unclassifiedExamplesJson: unclassifiedExamplesJson,
                rawHtml: rawHtml,
                source: source,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$WordMaterialsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({wordId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (wordId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.wordId,
                                referencedTable: $$WordMaterialsTableReferences
                                    ._wordIdTable(db),
                                referencedColumn: $$WordMaterialsTableReferences
                                    ._wordIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$WordMaterialsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WordMaterialsTable,
      WordMaterial,
      $$WordMaterialsTableFilterComposer,
      $$WordMaterialsTableOrderingComposer,
      $$WordMaterialsTableAnnotationComposer,
      $$WordMaterialsTableCreateCompanionBuilder,
      $$WordMaterialsTableUpdateCompanionBuilder,
      (WordMaterial, $$WordMaterialsTableReferences),
      WordMaterial,
      PrefetchHooks Function({bool wordId})
    >;
typedef $$AudioCachesTableCreateCompanionBuilder =
    AudioCachesCompanion Function({
      Value<int> id,
      required int wordId,
      required String variant,
      required String origin,
      required String path,
      required String format,
    });
typedef $$AudioCachesTableUpdateCompanionBuilder =
    AudioCachesCompanion Function({
      Value<int> id,
      Value<int> wordId,
      Value<String> variant,
      Value<String> origin,
      Value<String> path,
      Value<String> format,
    });

final class $$AudioCachesTableReferences
    extends BaseReferences<_$AppDatabase, $AudioCachesTable, AudioCache> {
  $$AudioCachesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WordsTable _wordIdTable(_$AppDatabase db) =>
      db.words.createAlias('audio_caches__word_id__words__id');

  $$WordsTableProcessedTableManager get wordId {
    final $_column = $_itemColumn<int>('word_id')!;

    final manager = $$WordsTableTableManager(
      $_db,
      $_db.words,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_wordIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AudioCachesTableFilterComposer
    extends Composer<_$AppDatabase, $AudioCachesTable> {
  $$AudioCachesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get variant => $composableBuilder(
    column: $table.variant,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnFilters(column),
  );

  $$WordsTableFilterComposer get wordId {
    final $$WordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableFilterComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AudioCachesTableOrderingComposer
    extends Composer<_$AppDatabase, $AudioCachesTable> {
  $$AudioCachesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get variant => $composableBuilder(
    column: $table.variant,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnOrderings(column),
  );

  $$WordsTableOrderingComposer get wordId {
    final $$WordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableOrderingComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AudioCachesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AudioCachesTable> {
  $$AudioCachesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get variant =>
      $composableBuilder(column: $table.variant, builder: (column) => column);

  GeneratedColumn<String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<String> get format =>
      $composableBuilder(column: $table.format, builder: (column) => column);

  $$WordsTableAnnotationComposer get wordId {
    final $$WordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableAnnotationComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AudioCachesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AudioCachesTable,
          AudioCache,
          $$AudioCachesTableFilterComposer,
          $$AudioCachesTableOrderingComposer,
          $$AudioCachesTableAnnotationComposer,
          $$AudioCachesTableCreateCompanionBuilder,
          $$AudioCachesTableUpdateCompanionBuilder,
          (AudioCache, $$AudioCachesTableReferences),
          AudioCache,
          PrefetchHooks Function({bool wordId})
        > {
  $$AudioCachesTableTableManager(_$AppDatabase db, $AudioCachesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AudioCachesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AudioCachesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AudioCachesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> wordId = const Value.absent(),
                Value<String> variant = const Value.absent(),
                Value<String> origin = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<String> format = const Value.absent(),
              }) => AudioCachesCompanion(
                id: id,
                wordId: wordId,
                variant: variant,
                origin: origin,
                path: path,
                format: format,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int wordId,
                required String variant,
                required String origin,
                required String path,
                required String format,
              }) => AudioCachesCompanion.insert(
                id: id,
                wordId: wordId,
                variant: variant,
                origin: origin,
                path: path,
                format: format,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AudioCachesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({wordId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (wordId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.wordId,
                                referencedTable: $$AudioCachesTableReferences
                                    ._wordIdTable(db),
                                referencedColumn: $$AudioCachesTableReferences
                                    ._wordIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AudioCachesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AudioCachesTable,
      AudioCache,
      $$AudioCachesTableFilterComposer,
      $$AudioCachesTableOrderingComposer,
      $$AudioCachesTableAnnotationComposer,
      $$AudioCachesTableCreateCompanionBuilder,
      $$AudioCachesTableUpdateCompanionBuilder,
      (AudioCache, $$AudioCachesTableReferences),
      AudioCache,
      PrefetchHooks Function({bool wordId})
    >;
typedef $$ReviewStatesTableTableCreateCompanionBuilder =
    ReviewStatesTableCompanion Function({
      Value<int> wordId,
      Value<bool> known,
      Value<int> interval,
      Value<DateTime?> nextReviewAt,
      Value<DateTime> updatedAt,
      Value<int> deviceSeq,
    });
typedef $$ReviewStatesTableTableUpdateCompanionBuilder =
    ReviewStatesTableCompanion Function({
      Value<int> wordId,
      Value<bool> known,
      Value<int> interval,
      Value<DateTime?> nextReviewAt,
      Value<DateTime> updatedAt,
      Value<int> deviceSeq,
    });

final class $$ReviewStatesTableTableReferences
    extends
        BaseReferences<_$AppDatabase, $ReviewStatesTableTable, ReviewState> {
  $$ReviewStatesTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $WordsTable _wordIdTable(_$AppDatabase db) =>
      db.words.createAlias('review_states_table__word_id__words__id');

  $$WordsTableProcessedTableManager get wordId {
    final $_column = $_itemColumn<int>('word_id')!;

    final manager = $$WordsTableTableManager(
      $_db,
      $_db.words,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_wordIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ReviewStatesTableTableFilterComposer
    extends Composer<_$AppDatabase, $ReviewStatesTableTable> {
  $$ReviewStatesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<bool> get known => $composableBuilder(
    column: $table.known,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get interval => $composableBuilder(
    column: $table.interval,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextReviewAt => $composableBuilder(
    column: $table.nextReviewAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deviceSeq => $composableBuilder(
    column: $table.deviceSeq,
    builder: (column) => ColumnFilters(column),
  );

  $$WordsTableFilterComposer get wordId {
    final $$WordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableFilterComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReviewStatesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ReviewStatesTableTable> {
  $$ReviewStatesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<bool> get known => $composableBuilder(
    column: $table.known,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get interval => $composableBuilder(
    column: $table.interval,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextReviewAt => $composableBuilder(
    column: $table.nextReviewAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deviceSeq => $composableBuilder(
    column: $table.deviceSeq,
    builder: (column) => ColumnOrderings(column),
  );

  $$WordsTableOrderingComposer get wordId {
    final $$WordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableOrderingComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReviewStatesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReviewStatesTableTable> {
  $$ReviewStatesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<bool> get known =>
      $composableBuilder(column: $table.known, builder: (column) => column);

  GeneratedColumn<int> get interval =>
      $composableBuilder(column: $table.interval, builder: (column) => column);

  GeneratedColumn<DateTime> get nextReviewAt => $composableBuilder(
    column: $table.nextReviewAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deviceSeq =>
      $composableBuilder(column: $table.deviceSeq, builder: (column) => column);

  $$WordsTableAnnotationComposer get wordId {
    final $$WordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableAnnotationComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReviewStatesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReviewStatesTableTable,
          ReviewState,
          $$ReviewStatesTableTableFilterComposer,
          $$ReviewStatesTableTableOrderingComposer,
          $$ReviewStatesTableTableAnnotationComposer,
          $$ReviewStatesTableTableCreateCompanionBuilder,
          $$ReviewStatesTableTableUpdateCompanionBuilder,
          (ReviewState, $$ReviewStatesTableTableReferences),
          ReviewState,
          PrefetchHooks Function({bool wordId})
        > {
  $$ReviewStatesTableTableTableManager(
    _$AppDatabase db,
    $ReviewStatesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReviewStatesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReviewStatesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReviewStatesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> wordId = const Value.absent(),
                Value<bool> known = const Value.absent(),
                Value<int> interval = const Value.absent(),
                Value<DateTime?> nextReviewAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> deviceSeq = const Value.absent(),
              }) => ReviewStatesTableCompanion(
                wordId: wordId,
                known: known,
                interval: interval,
                nextReviewAt: nextReviewAt,
                updatedAt: updatedAt,
                deviceSeq: deviceSeq,
              ),
          createCompanionCallback:
              ({
                Value<int> wordId = const Value.absent(),
                Value<bool> known = const Value.absent(),
                Value<int> interval = const Value.absent(),
                Value<DateTime?> nextReviewAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> deviceSeq = const Value.absent(),
              }) => ReviewStatesTableCompanion.insert(
                wordId: wordId,
                known: known,
                interval: interval,
                nextReviewAt: nextReviewAt,
                updatedAt: updatedAt,
                deviceSeq: deviceSeq,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ReviewStatesTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({wordId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (wordId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.wordId,
                                referencedTable:
                                    $$ReviewStatesTableTableReferences
                                        ._wordIdTable(db),
                                referencedColumn:
                                    $$ReviewStatesTableTableReferences
                                        ._wordIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ReviewStatesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReviewStatesTableTable,
      ReviewState,
      $$ReviewStatesTableTableFilterComposer,
      $$ReviewStatesTableTableOrderingComposer,
      $$ReviewStatesTableTableAnnotationComposer,
      $$ReviewStatesTableTableCreateCompanionBuilder,
      $$ReviewStatesTableTableUpdateCompanionBuilder,
      (ReviewState, $$ReviewStatesTableTableReferences),
      ReviewState,
      PrefetchHooks Function({bool wordId})
    >;
typedef $$PendingQueuesTableCreateCompanionBuilder =
    PendingQueuesCompanion Function({
      Value<int> id,
      required String kind,
      required String payload,
      Value<String> state,
    });
typedef $$PendingQueuesTableUpdateCompanionBuilder =
    PendingQueuesCompanion Function({
      Value<int> id,
      Value<String> kind,
      Value<String> payload,
      Value<String> state,
    });

class $$PendingQueuesTableFilterComposer
    extends Composer<_$AppDatabase, $PendingQueuesTable> {
  $$PendingQueuesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingQueuesTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingQueuesTable> {
  $$PendingQueuesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingQueuesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingQueuesTable> {
  $$PendingQueuesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);
}

class $$PendingQueuesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingQueuesTable,
          PendingQueue,
          $$PendingQueuesTableFilterComposer,
          $$PendingQueuesTableOrderingComposer,
          $$PendingQueuesTableAnnotationComposer,
          $$PendingQueuesTableCreateCompanionBuilder,
          $$PendingQueuesTableUpdateCompanionBuilder,
          (
            PendingQueue,
            BaseReferences<_$AppDatabase, $PendingQueuesTable, PendingQueue>,
          ),
          PendingQueue,
          PrefetchHooks Function()
        > {
  $$PendingQueuesTableTableManager(_$AppDatabase db, $PendingQueuesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingQueuesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingQueuesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingQueuesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<String> state = const Value.absent(),
              }) => PendingQueuesCompanion(
                id: id,
                kind: kind,
                payload: payload,
                state: state,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String kind,
                required String payload,
                Value<String> state = const Value.absent(),
              }) => PendingQueuesCompanion.insert(
                id: id,
                kind: kind,
                payload: payload,
                state: state,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingQueuesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingQueuesTable,
      PendingQueue,
      $$PendingQueuesTableFilterComposer,
      $$PendingQueuesTableOrderingComposer,
      $$PendingQueuesTableAnnotationComposer,
      $$PendingQueuesTableCreateCompanionBuilder,
      $$PendingQueuesTableUpdateCompanionBuilder,
      (
        PendingQueue,
        BaseReferences<_$AppDatabase, $PendingQueuesTable, PendingQueue>,
      ),
      PendingQueue,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableTableCreateCompanionBuilder =
    SettingsTableCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$SettingsTableTableUpdateCompanionBuilder =
    SettingsTableCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$SettingsTableTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTableTable> {
  $$SettingsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTableTable> {
  $$SettingsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTableTable> {
  $$SettingsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTableTable,
          SettingsTableData,
          $$SettingsTableTableFilterComposer,
          $$SettingsTableTableOrderingComposer,
          $$SettingsTableTableAnnotationComposer,
          $$SettingsTableTableCreateCompanionBuilder,
          $$SettingsTableTableUpdateCompanionBuilder,
          (
            SettingsTableData,
            BaseReferences<
              _$AppDatabase,
              $SettingsTableTable,
              SettingsTableData
            >,
          ),
          SettingsTableData,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableTableManager(_$AppDatabase db, $SettingsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) =>
                  SettingsTableCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => SettingsTableCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTableTable,
      SettingsTableData,
      $$SettingsTableTableFilterComposer,
      $$SettingsTableTableOrderingComposer,
      $$SettingsTableTableAnnotationComposer,
      $$SettingsTableTableCreateCompanionBuilder,
      $$SettingsTableTableUpdateCompanionBuilder,
      (
        SettingsTableData,
        BaseReferences<_$AppDatabase, $SettingsTableTable, SettingsTableData>,
      ),
      SettingsTableData,
      PrefetchHooks Function()
    >;
typedef $$BudgetDaysTableCreateCompanionBuilder =
    BudgetDaysCompanion Function({
      required String day,
      Value<int> count,
      Value<int> rowid,
    });
typedef $$BudgetDaysTableUpdateCompanionBuilder =
    BudgetDaysCompanion Function({
      Value<String> day,
      Value<int> count,
      Value<int> rowid,
    });

class $$BudgetDaysTableFilterComposer
    extends Composer<_$AppDatabase, $BudgetDaysTable> {
  $$BudgetDaysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BudgetDaysTableOrderingComposer
    extends Composer<_$AppDatabase, $BudgetDaysTable> {
  $$BudgetDaysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BudgetDaysTableAnnotationComposer
    extends Composer<_$AppDatabase, $BudgetDaysTable> {
  $$BudgetDaysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<int> get count =>
      $composableBuilder(column: $table.count, builder: (column) => column);
}

class $$BudgetDaysTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BudgetDaysTable,
          BudgetDay,
          $$BudgetDaysTableFilterComposer,
          $$BudgetDaysTableOrderingComposer,
          $$BudgetDaysTableAnnotationComposer,
          $$BudgetDaysTableCreateCompanionBuilder,
          $$BudgetDaysTableUpdateCompanionBuilder,
          (
            BudgetDay,
            BaseReferences<_$AppDatabase, $BudgetDaysTable, BudgetDay>,
          ),
          BudgetDay,
          PrefetchHooks Function()
        > {
  $$BudgetDaysTableTableManager(_$AppDatabase db, $BudgetDaysTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BudgetDaysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BudgetDaysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BudgetDaysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> day = const Value.absent(),
                Value<int> count = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BudgetDaysCompanion(day: day, count: count, rowid: rowid),
          createCompanionCallback:
              ({
                required String day,
                Value<int> count = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BudgetDaysCompanion.insert(
                day: day,
                count: count,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BudgetDaysTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BudgetDaysTable,
      BudgetDay,
      $$BudgetDaysTableFilterComposer,
      $$BudgetDaysTableOrderingComposer,
      $$BudgetDaysTableAnnotationComposer,
      $$BudgetDaysTableCreateCompanionBuilder,
      $$BudgetDaysTableUpdateCompanionBuilder,
      (BudgetDay, BaseReferences<_$AppDatabase, $BudgetDaysTable, BudgetDay>),
      BudgetDay,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$WordSetsTableTableManager get wordSets =>
      $$WordSetsTableTableManager(_db, _db.wordSets);
  $$WordsTableTableManager get words =>
      $$WordsTableTableManager(_db, _db.words);
  $$WordMaterialsTableTableManager get wordMaterials =>
      $$WordMaterialsTableTableManager(_db, _db.wordMaterials);
  $$AudioCachesTableTableManager get audioCaches =>
      $$AudioCachesTableTableManager(_db, _db.audioCaches);
  $$ReviewStatesTableTableTableManager get reviewStatesTable =>
      $$ReviewStatesTableTableTableManager(_db, _db.reviewStatesTable);
  $$PendingQueuesTableTableManager get pendingQueues =>
      $$PendingQueuesTableTableManager(_db, _db.pendingQueues);
  $$SettingsTableTableTableManager get settingsTable =>
      $$SettingsTableTableTableManager(_db, _db.settingsTable);
  $$BudgetDaysTableTableManager get budgetDays =>
      $$BudgetDaysTableTableManager(_db, _db.budgetDays);
}
