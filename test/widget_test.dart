import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:read_words/data/app_database.dart';

void main() {
  test('database schema opens and migrates to v1', () async {
    final db = AppDatabase(NativeDatabase.memory());
    await db.customSelect('SELECT 1 FROM sqlite_master LIMIT 1').get();
    expect(db.schemaVersion, 1);
    await db.close();
  });
}
