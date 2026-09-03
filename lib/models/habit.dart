import 'dart:convert';

/// Calendar dates use UTC midnight for arithmetic, independent of DST.
DateTime calendarDate(DateTime value) =>
    DateTime.utc(value.year, value.month, value.day);
String dateKey(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

class Habit {
  Habit({
    required this.goal,
    required this.action,
    required this.startedAt,
    this.hour = 20,
    this.minute = 0,
    this.notificationsEnabled = true,
    Set<String> completedDates = const {},
  }) : completedDates = Set.unmodifiable(completedDates);

  final String goal;
  final String action;
  final DateTime startedAt;
  final int hour;
  final int minute;
  final bool notificationsEnabled;
  final Set<String> completedDates;

  String get timeLabel =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  bool isDone(DateTime date) => completedDates.contains(dateKey(date));
  int elapsedDays(DateTime now) =>
      (calendarDate(now).difference(calendarDate(startedAt)).inDays + 1).clamp(
        1,
        999999,
      );
  int total(DateTime now) => completedDates
      .where(
        (key) =>
            key.compareTo(dateKey(now)) <= 0 &&
            key.compareTo(dateKey(startedAt)) >= 0,
      )
      .length;
  int rate(DateTime now) =>
      (total(now) / elapsedDays(now) * 100).round().clamp(0, 100);

  int streak(DateTime now) {
    var day = calendarDate(now);
    if (!isDone(day)) day = day.subtract(const Duration(days: 1));
    var count = 0;
    while (!day.isBefore(calendarDate(startedAt)) && isDone(day)) {
      count++;
      day = day.subtract(const Duration(days: 1));
    }
    return count;
  }

  Habit copyWith({
    String? goal,
    String? action,
    int? hour,
    int? minute,
    bool? notificationsEnabled,
    Set<String>? completedDates,
  }) => Habit(
    goal: goal ?? this.goal,
    action: action ?? this.action,
    startedAt: startedAt,
    hour: hour ?? this.hour,
    minute: minute ?? this.minute,
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    completedDates: completedDates ?? this.completedDates,
  );

  Habit toggleDate(DateTime date, DateTime now) {
    final day = calendarDate(date);
    if (day.isBefore(calendarDate(startedAt)) ||
        day.isAfter(calendarDate(now))) {
      throw ArgumentError('記録できるのは開始日から今日までです。');
    }
    final dates = {...completedDates};
    final key = dateKey(day);
    if (!dates.remove(key)) dates.add(key);
    return copyWith(completedDates: dates);
  }

  String encode() => jsonEncode({
    'version': 1,
    'goal': goal,
    'action': action,
    'startedAt': dateKey(startedAt),
    'hour': hour,
    'minute': minute,
    'notificationsEnabled': notificationsEnabled,
    'completedDates': completedDates.toList()..sort(),
  });

  factory Habit.decode(String source) {
    final data = jsonDecode(source) as Map<String, dynamic>;
    if (data['version'] != 1) throw const FormatException('未対応のデータ形式です。');
    DateTime parseDay(String key) {
      final value = DateTime.parse(key);
      if (dateKey(value) != key) throw const FormatException('日付が正しくありません。');
      return calendarDate(value);
    }

    final start = parseDay(data['startedAt'] as String);
    final goal = data['goal'] as String;
    final action = data['action'] as String;
    final hour = data['hour'] as int;
    final minute = data['minute'] as int;
    if (goal.trim().isEmpty ||
        action.trim().isEmpty ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      throw const FormatException('設定値が正しくありません。');
    }
    final dates = (data['completedDates'] as List).cast<String>().toSet();
    for (final key in dates) {
      if (parseDay(key).isBefore(start)) {
        throw const FormatException('開始日前の記録です。');
      }
    }
    return Habit(
      goal: goal,
      action: action,
      startedAt: start,
      hour: hour,
      minute: minute,
      notificationsEnabled: data['notificationsEnabled'] as bool,
      completedDates: dates,
    );
  }
}
