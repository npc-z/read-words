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
