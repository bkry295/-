import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit.dart';

abstract interface class HabitRepository {
  Future<Habit?> load();
  Future<void> save(Habit habit);
}

class LocalHabitRepository implements HabitRepository {
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  static const storageKey = 'mainichi.habit.v1';

  @override
  Future<Habit?> load() async {
    final source = await _preferences.getString(storageKey);
    return source == null ? null : Habit.decode(source);
  }

  @override
  Future<void> save(Habit habit) =>
      _preferences.setString(storageKey, habit.encode());
}
