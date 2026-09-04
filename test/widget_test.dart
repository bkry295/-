import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mainichi/app.dart';
import 'package:mainichi/models/habit.dart';
import 'package:mainichi/services/habit_repository.dart';
import 'package:mainichi/services/reminders.dart';

class MemoryRepository implements HabitRepository {
  Habit? habit;
  bool failSave = false;
  bool failLoad = false;
  @override
  Future<Habit?> load() async {
    if (failLoad) throw Exception('read error');
    return habit;
  }

  @override
  Future<void> save(Habit value) async {
    if (failSave) throw Exception('disk full');
    habit = value;
  }
}

class FakeReminders implements ReminderService {
  @override
  bool get supported => false;
  @override
  Future<String?> configure(
    Habit habit, {
    bool requestPermission = false,
  }) async => null;
  @override
  Future<String> test(Habit habit) async => '通知のテストはAndroid・iPhoneアプリで利用できます。';
}

Future<void> openApp(
  WidgetTester tester,
  MemoryRepository repository, {
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MainichiApp(repository: repository, reminders: FakeReminders()),
  );
  await tester.pumpAndSettle();
}

Habit sampleHabit() => Habit(
  goal: '英語を話せるようになる',
  action: '英単語を10個覚える',
  startedAt: calendarDate(DateTime.now()),
);

void main() {
  testWidgets('onboarding, completion, reload, and undo persist correctly', (
    tester,
  ) async {
    final repository = MemoryRepository();
    await openApp(tester, repository);
    expect(find.text('小さな一歩を、毎日に。'), findsOneWidget);
    await tester.ensureVisible(find.text('この内容ではじめる'));
    await tester.tap(find.text('この内容ではじめる'));
    await tester.pumpAndSettle();
    expect(repository.habit!.action, '英単語を10個覚える');
    await tester.tap(find.text('今日の実行を完了'));
    await tester.pumpAndSettle();
    expect(repository.habit!.total(DateTime.now()), 1);
    expect(find.text('今日もできました！'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      MainichiApp(repository: repository, reminders: FakeReminders()),
    );
    await tester.pumpAndSettle();
    expect(find.text('今日もできました！'), findsOneWidget);
    await tester.tap(find.text('記録を取り消す'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('取り消す'));
    await tester.pumpAndSettle();
    expect(repository.habit!.total(DateTime.now()), 0);
    expect(find.text('今日の実行を完了'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'settings editing and time changes survive saving and navigation',
    (tester) async {
      final repository = MemoryRepository()..habit = sampleHabit();
      await openApp(tester, repository);
      await tester.tap(find.text('設定'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('英語を話せるようになる'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '毎日、本を読む');
      await tester.tap(find.text('変更する'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('通知時間'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), '21');
      await tester.enterText(find.byType(TextField).at(1), '30');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('保存'));
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      expect(repository.habit!.goal, '毎日、本を読む');
      expect(repository.habit!.timeLabel, '21:30');
      await tester.tap(find.text('今日'));
      await tester.pumpAndSettle();
      expect(find.text('毎日 21:30 に通知'), findsOneWidget);
      await tester.tap(find.text('記録'));
      await tester.pumpAndSettle();
    expect(find.text('実行回数の推移（累計）'), findsNothing);
      expect(find.text('日付をタップして編集'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('failed save leaves completion unchanged and allows retry', (
    tester,
  ) async {
    final repository = MemoryRepository()
      ..habit = sampleHabit()
      ..failSave = true;
    await openApp(tester, repository);
    await tester.tap(find.text('今日の実行を完了'));
    await tester.pumpAndSettle();
    expect(repository.habit!.completedDates, isEmpty);
    expect(find.textContaining('保存できませんでした'), findsOneWidget);
    expect(find.text('今日の実行を完了'), findsOneWidget);
    repository.failSave = false;
    await tester.tap(find.text('今日の実行を完了'));
    await tester.pumpAndSettle();
    expect(repository.habit!.completedDates.length, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('load failure does not overwrite stored data', (tester) async {
    final repository = MemoryRepository()
      ..habit = sampleHabit()
      ..failLoad = true;
    await openApp(tester, repository);
    expect(find.text('記録を読み込めませんでした'), findsOneWidget);
    expect(repository.habit, isNotNull);
    repository.failLoad = false;
    await tester.tap(find.text('再読み込み'));
    await tester.pumpAndSettle();
    expect(find.text('今日の実行を完了'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('small phone renders all tabs and calendar backfill works', (
    tester,
  ) async {
    final now = calendarDate(DateTime.now());
    final repository = MemoryRepository()
      ..habit = Habit(
        goal: '長い目標も画面からはみ出さずに読みやすく表示できるようになる',
        action: '毎日続けられる小さなことをひとつ決めて実行する',
        startedAt: now.subtract(const Duration(days: 40)),
      );
    await openApp(tester, repository, size: const Size(320, 568));
    expect(tester.takeException(), isNull);
    expect(find.text('実行の記録'), findsNothing);
    await tester.tap(find.text('記録'));
    await tester.pumpAndSettle();
    expect(find.text('実行の記録'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('実行の記録')).dy,
      lessThan(tester.getTopLeft(find.text('${now.year}年 ${now.month}月')).dy),
    );
    await tester.ensureVisible(find.text('${now.day}').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('${now.day}').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('この日の実行を記録'));
    await tester.pumpAndSettle();
    expect(repository.habit!.isDone(now), isTrue);
    await tester.tap(find.byTooltip('前の月'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('設定'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('保存'));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
