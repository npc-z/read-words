import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:read_words/data/app_database.dart';
import 'package:read_words/data/repositories.dart';
import 'package:read_words/data/settings.dart';
import 'package:read_words/ui/settings_page.dart';
import 'package:read_words/ui/word_set_list_page.dart';

void main() {
  late AppDatabase db;
  late Repositories repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = Repositories(db);
  });

  tearDown(() => db.close());

  Future<void> pumpSettings(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: SettingsPage(repositories: repo)));
    await tester.pumpAndSettle();
  }

  testWidgets('renders defaults when nothing stored', (tester) async {
    await pumpSettings(tester);

    expect(find.text('高考'), findsOneWidget);
    expect(find.widgetWithText(TextField, '50'), findsOneWidget);
    expect(find.widgetWithText(TextField, '3'), findsOneWidget);
    expect(find.widgetWithText(TextField, '4'), findsOneWidget);
    expect(find.text('学习模式'), findsOneWidget);
    expect(find.text('中英双语'), findsOneWidget);
  });

  testWidgets('renders stored values', (tester) async {
    await repo.saveSettings(const AppSettings(
      level: EnglishLevel.cet46,
      dailyReadingX: 30,
      budgetMultiple: 2,
      concurrency: 8,
      apiKey: 'sk-abc',
      defaultViewMode: ViewMode.review,
      displayMode: DisplayMode.en,
    ));
    await pumpSettings(tester);

    expect(find.text('四六级'), findsOneWidget);
    expect(find.widgetWithText(TextField, '30'), findsOneWidget);
    expect(find.widgetWithText(TextField, '2'), findsOneWidget);
    expect(find.widgetWithText(TextField, '8'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'sk-abc'), findsOneWidget);
    expect(find.text('复习模式'), findsOneWidget);
    expect(find.text('仅英文'), findsOneWidget);
  });

  testWidgets('changing level persists immediately', (tester) async {
    await pumpSettings(tester);

    await tester.tap(find.text('四六级'));
    await tester.pumpAndSettle();

    expect((await repo.settings()).level, EnglishLevel.cet46);
  });

  testWidgets('typing numbers persists immediately', (tester) async {
    await pumpSettings(tester);

    await tester.enterText(find.widgetWithText(TextField, '50'), '25');
    await tester.pumpAndSettle();
    expect((await repo.settings()).dailyReadingX, 25);

    await tester.enterText(find.widgetWithText(TextField, '3'), '5');
    await tester.pumpAndSettle();
    expect((await repo.settings()).budgetMultiple, 5);
  });

  testWidgets('typing api key persists immediately', (tester) async {
    await pumpSettings(tester);

    await tester.enterText(
      find.widgetWithText(TextField, 'AI API Key(OpenAI 兼容)'),
      'sk-new',
    );
    await tester.pumpAndSettle();

    expect((await repo.settings()).apiKey, 'sk-new');
  });

  testWidgets('invalid or zero numbers are not persisted and revert on blur', (tester) async {
    await pumpSettings(tester);

    // 非法输入:不持久化
    await tester.enterText(find.widgetWithText(TextField, '50'), 'abc');
    await tester.pumpAndSettle();
    expect((await repo.settings()).dailyReadingX, 50);

    // 0:不持久化(预算基数语义需 ≥1)
    await tester.enterText(find.widgetWithText(TextField, 'abc'), '0');
    await tester.pumpAndSettle();
    expect((await repo.settings()).dailyReadingX, 50);

    // 失焦回退:输入非法值后失焦,字段恢复持久化值
    await tester.enterText(find.widgetWithText(TextField, '0'), '12x');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, '50'), findsOneWidget);
  });

  testWidgets('changing view mode and display mode persists immediately', (tester) async {
    await pumpSettings(tester);

    await tester.tap(find.text('学习模式'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('查阅模式').last);
    await tester.pumpAndSettle();
    expect((await repo.settings()).defaultViewMode, ViewMode.lookup);

    await tester.tap(find.text('中英双语'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('仅中文').last);
    await tester.pumpAndSettle();
    expect((await repo.settings()).displayMode, DisplayMode.zh);
  });

  testWidgets('word set list page has settings entry that opens the page', (tester) async {
    await tester.pumpWidget(MaterialApp(home: WordSetListPage(repositories: repo)));
    await tester.pumpAndSettle();

    expect(find.byTooltip('设置'), findsOneWidget);
    await tester.tap(find.byTooltip('设置'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, '设置'), findsOneWidget);
    expect(find.widgetWithText(TextField, '50'), findsOneWidget);
  });
}
