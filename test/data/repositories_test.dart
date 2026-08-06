import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:read_words/data/app_database.dart';
import 'package:read_words/data/repositories.dart';

void main() {
  late AppDatabase db;
  late Repositories repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = Repositories(db);
  });

  tearDown(() => db.close());

  group('WordSets', () {
    test('create word set', () async {
      final id = await repo.createWordSet('高考词汇');
      final sets = await repo.wordSets();
      expect(sets, hasLength(1));
      expect(sets.first.name, '高考词汇');
      expect(id, greaterThan(0));
    });
  });

  group('Words import & dedup', () {
    test('add words to set, dedup on re-import', () async {
      final setId = await repo.createWordSet('高考词汇');
      final added = await repo.addWords(setId, ['run', 'apple', 'run']);
      expect(added, 2);

      final words = await repo.wordsInSet(setId);
      expect(words, hasLength(2));
      expect(words.map((w) => w.headword).toSet(), {'run', 'apple'});

      final added2 = await repo.addWords(setId, ['run', 'book']);
      expect(added2, 1);
      expect(await repo.wordsInSet(setId), hasLength(3));
    });
  });

  group('WordMaterials', () {
    test('store and update material', () async {
      final setId = await repo.createWordSet('test');
      final wordId = await repo.addWords(setId, ['run']).then((_) async {
        return (await repo.wordsInSet(setId)).first.id;
      });

      final json = '{"senses":[],"phrases":[]}';
      await repo.saveMaterial(wordId, MaterialData(
        phoneticUk: '/rʌn/',
        phoneticUs: '/rʌn/',
        sensesJson: json,
        phrasesJson: '[]',
        unclassifiedExamplesJson: '[]',
        source: 'ai',
      ));

      final m = await repo.materialFor(wordId);
      expect(m, isNotNull);
      expect(m!.phoneticUk, '/rʌn/');
      expect(m.source, 'ai');
    });
  });

  group('ReviewState', () {
    test('mark known/unknown, update interval', () async {
      final setId = await repo.createWordSet('test');
      final wordId = (await repo.addWords(setId, ['run']).then(
        (_) => repo.wordsInSet(setId),
      ))
          .first
          .id;

      await repo.markKnown(wordId, known: false);
      var r = await repo.reviewStateFor(wordId);
      expect(r, isNotNull);
      expect(r!.known, false);
      expect(r.interval, 1);

      await repo.markKnown(wordId, known: true);
      r = await repo.reviewStateFor(wordId);
      expect(r!.known, true);

      await repo.advanceReview(wordId);
      r = await repo.reviewStateFor(wordId);
      expect(r!.interval, 3);
      expect(r.nextReviewAt, isNotNull);
    });

    test('first mark schedules first review in 1 day, re-mark keeps schedule', () async {
      final setId = await repo.createWordSet('test');
      final wordId = (await repo.addWords(setId, ['run']).then(
        (_) => repo.wordsInSet(setId),
      ))
          .first
          .id;

      final before = DateTime.now();
      await repo.markKnown(wordId, known: true);
      var r = await repo.reviewStateFor(wordId);
      expect(r, isNotNull);
      expect(r!.interval, 1);
      expect(r.nextReviewAt, isNotNull);
      expect(r.nextReviewAt!.isAfter(before), isTrue);
      expect(
        r.nextReviewAt!.difference(before).inHours,
        inInclusiveRange(20, 28),
      );

      // 重复标记:只更新标记,不重置排期
      final scheduled = r.nextReviewAt;
      await repo.markKnown(wordId, known: false);
      r = await repo.reviewStateFor(wordId);
      expect(r!.known, false);
      expect(r.nextReviewAt, scheduled);
      expect(r.interval, 1);
    });

    test('advanceReview ladder 1 -> 3 -> 7 -> 7 with next date set', () async {
      final setId = await repo.createWordSet('test');
      final wordId = (await repo.addWords(setId, ['run']).then(
        (_) => repo.wordsInSet(setId),
      ))
          .first
          .id;

      await repo.markKnown(wordId, known: true);
      await repo.advanceReview(wordId);
      var r = await repo.reviewStateFor(wordId);
      expect(r!.interval, 3);
      expect(r.nextReviewAt!.isAfter(DateTime.now()), isTrue);

      await repo.advanceReview(wordId);
      r = await repo.reviewStateFor(wordId);
      expect(r!.interval, 7);

      await repo.advanceReview(wordId);
      r = await repo.reviewStateFor(wordId);
      expect(r!.interval, 7);
    });
  });

  group('Review due list', () {
    Future<(int, int)> addWord(String set, String head) async {
      final setId = await repo.createWordSet(set);
      await repo.addWords(setId, [head]);
      return (setId, (await repo.wordsInSet(setId)).first.id);
    }

    Future<void> writeState(
      int wordId, {
      bool known = true,
      int interval = 1,
      required int daysAgo,
    }) async {
      await db.into(db.reviewStatesTable).insertOnConflictUpdate(
            ReviewStatesTableCompanion.insert(
              wordId: Value(wordId),
              known: Value(known),
              interval: Value(interval),
              nextReviewAt: Value(
                DateTime.now().subtract(Duration(days: daysAgo)),
              ),
              updatedAt: Value(DateTime.now()),
              deviceSeq: const Value(1),
            ),
          );
    }

    test('only due and overdue words in the set, sorted by nextReviewAt', () async {
      final (setId, a) = await addWord('s', 'a'); // 逾期 2 天
      final (_, b) = await addWord('s', 'b'); // 未到期(未来)
      await addWord('s', 'c'); // 无复习状态
      final (_, d) = await addWord('other', 'd'); // 他集到期
      await writeState(a, daysAgo: 2);
      await writeState(b, daysAgo: -3);
      await writeState(d, daysAgo: 1);

      final due = await repo.dueReviewWords(setId);
      expect(due.map((w) => w.headword).toList(), ['a']);
    });

    test('overdue words ordered earliest first', () async {
      final setId = await repo.createWordSet('s');
      await repo.addWords(setId, ['a', 'e']);
      final words = await repo.wordsInSet(setId);
      await writeState(words[0].id, daysAgo: 2); // a
      await writeState(words[1].id, daysAgo: 5); // e 更早到期

      final due = await repo.dueReviewWords(setId);
      expect(due.map((w) => w.headword).toList(), ['e', 'a']);
      expect(await repo.dueReviewCount(setId), 2);
    });
  });

  group('Settings', () {
    test('set/get round trip, missing key returns null', () async {
      expect(await repo.getSetting(SettingsKeys.apiKey), isNull);

      await repo.setSetting(SettingsKeys.apiKey, 'sk-test');
      expect(await repo.getSetting(SettingsKeys.apiKey), 'sk-test');

      await repo.setSetting(SettingsKeys.apiKey, 'sk-new');
      expect(await repo.getSetting(SettingsKeys.apiKey), 'sk-new');
    });
  });
}
