import 'package:flutter_test/flutter_test.dart';
import 'package:mainichi/models/habit.dart';

void main() {
  Habit habit(Set<String> dates) => Habit(
    goal: '目標',
    action: '行動',
    startedAt: DateTime.utc(2026, 8, 30),
    completedDates: dates,
  );
  final today = DateTime(2026, 9, 3, 20);

  test('streak crosses month boundary and tolerates unfinished today', () {
    final value = habit({
      '2026-08-30',
      '2026-08-31',
      '2026-09-01',
      '2026-09-02',
    });
    expect(value.streak(today), 4);
    expect(value.total(today), 4);
    expect(value.elapsedDays(today), 5);
    expect(value.rate(today), 80);
    final done = value.toggleDate(today, today);
    expect(done.streak(today), 5);
    expect(done.rate(today), 100);
    expect(done.toggleDate(today, today).rate(today), 80);
  });

  test('missing yesterday resets streak but preserves total', () {
    final value = habit({'2026-08-30', '2026-08-31', '2026-09-01'});
    expect(value.streak(today), 0);
    expect(value.total(today), 3);
    expect(value.toggleDate(today, today).streak(today), 1);
  });

  test('future and pre-start dates cannot be recorded', () {
    final value = habit({});
    expect(
      () => value.toggleDate(DateTime(2026, 8, 29), today),
      throwsArgumentError,
    );
    expect(
      () => value.toggleDate(DateTime(2026, 9, 4), today),
      throwsArgumentError,
    );
    expect(value.total(today), 0);
    expect(value.rate(today), 0);
  });

  test('serialization retains settings, unique dates, and calendar dates', () {
    final value = habit({
      '2026-08-31',
      '2026-09-02',
    }).copyWith(hour: 7, minute: 5, notificationsEnabled: false);
    final decoded = Habit.decode(value.encode());
    expect(decoded.completedDates, value.completedDates);
    expect(decoded.timeLabel, '07:05');
    expect(decoded.notificationsEnabled, isFalse);
    expect(decoded.startedAt, DateTime.utc(2026, 8, 30));
    expect(
      () => decoded.completedDates.add('2026-09-03'),
      throwsUnsupportedError,
    );
  });

  test('malformed and unsupported storage is rejected', () {
    expect(() => Habit.decode('{broken'), throwsFormatException);
    expect(() => Habit.decode('{"version":2}'), throwsFormatException);
    final valid = habit({}).encode();
    expect(
      () => Habit.decode(valid.replaceFirst('"hour":20', '"hour":25')),
      throwsFormatException,
    );
    expect(
      () => Habit.decode(valid.replaceFirst('2026-08-30', '2026-02-30')),
      throwsFormatException,
    );
  });

  test('calendar-day arithmetic ignores hours and daylight saving lengths', () {
    final value = Habit(
      goal: 'a',
      action: 'b',
      startedAt: DateTime(2026, 3, 7, 23, 59),
    );
    expect(value.elapsedDays(DateTime(2026, 3, 9, 0, 1)), 3);
    expect(value.copyWith(goal: '新しい目標').startedAt, value.startedAt);
  });
}
